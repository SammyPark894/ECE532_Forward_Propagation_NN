`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 03/06/2022 07:47:24 PM
// Design Name: 
// Module Name: meanMod
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments: Really hoping this bad boy is as short as I think it is
// 
//////////////////////////////////////////////////////////////////////////////////


module meanMod(
        input clk,
        input resetn,
        input startFlag,
        input [31:0] in[0:1][0:1],
        input readyNext,
        output initShakeO,
        output handOff,
        output [31:0] out
    );
    
    enum reg [3:0] {INITWAIT, INITHAND, ADD, ADD_DONE, UPDATELOC, DIVIDE, DIVIDE_DONE, ENDWAIT, CLEANUP} STATES;
    
    reg [3:0] curState;
    reg [3:0] nextState;
    reg [31:0] addSelected;
    reg [31:0] outREG;
    
    //outputs of floating point units
     reg [31:0] f1Out;
     reg [31:0] f2Out;
    //TODO all inputs should be moved to intermediate registers on the initial steps, otherwise if we pipeline there will be continuous changing of input
    reg xLoc;//making this one bigger for termination condition
    reg yLoc;
    
    //these would be inputs for handoffs if I was using the floating point unit, which I am not
    wire divDone;
    wire addDone;
    
    /////assign addDone=1'b1;
    /////assign divDone=1'b1;
    assign out=outREG;
    
    //back to my control signals again
    reg initShake;
    reg addInit;
    reg addInitDone;
    reg incrementLoc;
    reg divInit;
    reg divInitDone;
    reg endShake;
    reg clean;
    
    assign handOff=endShake;
    assign initShakeO=initShake;
    
    //control
    always@(posedge clk)begin
        initShake=1'b0;
        addInit=1'b0;
        addInitDone=1'b0;
        incrementLoc=1'b0;
        divInit=1'b0;
        divInitDone=1'b0;
        endShake=1'b0;
        clean=1'b0;
        
        if(resetn==1'b0)begin
            //next time we go to start
            curState=INITWAIT;
            nextState=INITWAIT;
        end
        
        else begin
            curState=nextState;
            case(curState)
                INITWAIT:begin
                    if(startFlag==1'b1)begin
                        nextState=INITHAND;
                    end
                    else begin
                        nextState=curState;
                    end
                end
                INITHAND:begin
                    initShake=1'b1;
                    nextState=ADD;
                end
                ADD:begin
                    addInit=1'b1;
                    nextState=ADD_DONE;
                end
                ADD_DONE:begin
                    if(addDone)begin
                        addInitDone=1'b1;
                        nextState=UPDATELOC;
                    end
                    else begin
                        nextState=curState;
                    end
                end
                UPDATELOC:begin
                    if(xLoc!=1'b1 || yLoc!=1'b1)begin
                        incrementLoc=1'b1;
                        nextState=ADD;
                    end
                    else begin
                        nextState=DIVIDE;
                    end
                end
                DIVIDE:begin
                    divInit=1'b1;
                    nextState=DIVIDE_DONE;
                end
                DIVIDE_DONE:begin
                    if(divDone)begin
                        divInitDone=1'b1;
                        nextState=ENDWAIT;
                    end
                    else begin
                        nextState=curState;
                    end
                end
                ENDWAIT:begin
                    if(readyNext==1'b1)begin
                        nextState=CLEANUP;
                    end
                    else begin
                        endShake=1'b1;
                        nextState=ENDWAIT;
                    end
                end
                CLEANUP:begin
                    clean=1'b1;
                    nextState=INITWAIT;
                end
            endcase
        end
    end
    
    //datapath
    always@(negedge clk)begin
        if(resetn==1'b0)begin
            outREG<=32'b0;
            xLoc<=2'b0;
            yLoc=2'b0;
        end
        else begin
            if(addInit)begin
                //outREG<=32'b0;
                /////outREG<=outREG+addSelected;
            end
            else if(addInitDone)begin
                outREG<=f1Out;
            end
            else if(incrementLoc)begin
                if(xLoc<1'b1)begin
                    xLoc<=xLoc+1'b1;
                end
                else begin
                    yLoc<=yLoc+1'b1;
                    xLoc<=1'b0;
                end
            end
            else if(divInit)begin
                /////outREG<=outREG/4;//I can also shift right here, and I probably will end up doing something like this
            end
            else if(divInitDone)begin
                outREG<=f2Out;
            end
            else if(clean)begin
                //outREG<=32'b0;
                xLoc<=2'b0;
                yLoc=2'b0;
            end
        end
    end
    
    addSelect a1(.in(in), .xLoc(xLoc), .yLoc(yLoc), .addSelected(addSelected));
    
    //my floating point units
    FPUnit f1(.clk(clk), .resetn(resetn), .operation(2'b00), .firstOp(outREG), .secondOp(addSelected), .start(addInit), .done(addDone), .finalRes(f1Out));
    
    //multiply by 0.25 to divide by 4, was going to cheat but not much faster and doesn't handle 0 case
    FPUnit f2(.clk(clk), .resetn(resetn), .operation(2'b10), .firstOp(outREG), .secondOp(32'b00111110100000000000000000000000), .start(divInit), .done(divDone), .finalRes(f2Out));
    
endmodule


module addSelect(input [31:0] in[0:1][0:1], input xLoc, input yLoc, output reg [31:0] addSelected);
    always@(*)begin
        case({xLoc, yLoc})
            2'b00:begin
                addSelected<=in[0][0];
            end
            2'b01:begin
                addSelected<=in[0][1];
            end
            2'b10:begin
                addSelected<=in[1][0];
            end
            2'b11:begin
                addSelected<=in[1][1];
            end
        endcase
    end
endmodule