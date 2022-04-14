`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 03/07/2022 12:46:03 AM
// Design Name: 
// Module Name: linLay
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments: I'm a little lucky a lot of these have a lot of re-use
// 
//////////////////////////////////////////////////////////////////////////////////


module linLay(
        input clk, 
        input resetn,
        input startFlag,
        input [31:0] in,
        input [31:0] win [0:9],
        input readyNext,
        output initShakeO,
        output handOff,
        output [31:0] out [0:9],
        
        //debug
        
        output [31:0] copyIn_out,
        output [31:0] selectedWeight_out,
        output [31:0] f1Out_out,
        
        output [31:0] curResult_out,
        output [31:0] selectedBias_out,
        output [31:0] f2Out_out,
        
        output [47:0] Om_out,
        output [46:0] Xm_out,
        output [46:0] Ym_out,
        output [7:0] toShift_out
    );
    
    enum reg [3:0] {INITWAIT, INITHAND, MULT, MULT_DONE, ADD, ADD_DONE, WRITEOUT, UPDATELOC, ENDWAIT, ENDWAIT2, CLEANUP} STATE;
    
    reg [3:0] curState;
    reg [3:0] nextState;
    
    reg [31:0] copyIn;
    reg [31:0] addSelected;
    reg [31:0] outREG [0:9];
    reg [31:0] curResult;
    reg [3:0] location;
    
    //outputs of floating point units
     reg [31:0] f1Out;
     reg [31:0] f2Out;
    
    wire multDone;
    wire addDone;
    
    /////assign addDone=1'b1;
    /////assign multDone=1'b1;
    assign out=outREG;
    
    
    
    
    reg initShake;
    reg multInit;
    reg multInitDone;
    reg addInit;
    reg addInitDone;
    reg write;
    reg incrementLoc;
    reg endShake;
    reg clean;
    
    assign handOff=endShake;
    assign initShakeO=initShake;
    
    reg [31:0] weights[0:9];
    reg [31:0] bias[0:9];
    /*initial begin
        weights[0]=32'h3F800000;
        weights[1]=32'h40000000;
        weights[2]=32'h40400000;
        weights[3]=32'h40800000;
        weights[4]=32'h40A00000;
        weights[5]=32'h40C00000;
        weights[6]=32'h40E00000;
        weights[7]=32'h41000000;
        weights[8]=32'h41100000;
        weights[9]=32'h41200000;
    end*/
    
    always @ (posedge clk) begin
        weights = win;
        bias[0] = 32'b10111111100100101000111101011110;
        bias[1] = 32'b01000000001010000010100011110001;
        bias[2] = 32'b10111111100001111100110001110100;
        bias[3] = 32'b11000000000101010110110100100100;
        bias[4] = 32'b00111111100010100000111010011100;
        bias[5] = 32'b10111111111000110111110100100000;
        bias[6] = 32'b10111101101010011011101010110000;
        bias[7] = 32'b01000000000110011011000101111111;
        bias[8] = 32'b10111111000110010100110001101001;
        bias[9] = 32'b00111111011001000110000111100000;
    end
    
    //debug
    //assign out = win;
    assign wout0 = f2Out;
    assign bias0 = f1Out;
    assign in0 = in;
   
   assign copyIn_out = copyIn;
   assign selectedWeight_out  = selectedWeight;
   assign f1Out_out = f1Out;

   assign curResult_out = curResult;
   assign selectedBias_out = selectedBias;
   assign f2Out_out = f2Out;
    
    reg [31:0] selectedWeight;
    reg [31:0] selectedBias;
    
    //Control once more
    always@(posedge clk)begin
        initShake=1'b0;
        multInit=1'b0;
        multInitDone=1'b0;
        addInit=1'b0;
        addInitDone=1'b0;
        write=1'b0;
        incrementLoc=1'b0;
        endShake=1'b0;
        clean=1'b0;
        if(resetn==1'b0)begin
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
                    nextState=MULT;
                end
                MULT:begin
                    multInit=1'b1;
                    nextState=MULT_DONE;
                end
                MULT_DONE:begin
                    if(multDone)begin
                        multInitDone=1'b1;
                        nextState=ADD;
                    end
                    else begin
                        nextState=MULT_DONE;
                    end
                end
                ADD:begin
                    addInit=1'b1;
                    nextState=ADD_DONE;
                end
                ADD_DONE:begin
                    if(addDone)begin
                        addInitDone=1'b1;
                        nextState=WRITEOUT;
                    end
                    else begin
                        nextState=ADD_DONE;
                    end
                end
                WRITEOUT:begin
                    write=1'b1;
                    nextState=UPDATELOC;
                end
                UPDATELOC:begin
                    //clear curResult here too
                    if(location<4'b1001)begin
                        incrementLoc=1'b1;
                        nextState=MULT;
                    end
                    else begin
                        nextState=ENDWAIT;
                    end
                end
                ENDWAIT:begin
                    if(readyNext==1'b1)begin
                        nextState=ENDWAIT2;
                    end
                    else begin
                        endShake=1'b1;
                        nextState=ENDWAIT;
                    end
                end
                ENDWAIT2: begin
                    nextState=CLEANUP;
                end
                CLEANUP:begin
                    clean=1'b1;
                    nextState=INITWAIT;
                end
            endcase
        end
    end
    
    always@(posedge clk)begin
        if(resetn==1'b0)begin
            curResult=32'b0;
            location=4'b0;
        end
        else begin
            if(initShake)begin
                copyIn=in;
            end
            if(multInit)begin
                /////curResult=copyIn*selectedWeight;
            end
            if(multInitDone)begin
                curResult=f1Out;
            end
            if(addInit)begin
                //there is only a single b value here anyways
                /////curResult=curResult+4'b1010;
            end
            if(addInitDone)begin
                curResult=f2Out;
            end
            if(incrementLoc)begin
                curResult=32'b0;
                location=location+1'b1;
            end
            if(clean)begin
                curResult=32'b0;
                location=4'b0;
            end
        end
    end
    
    multSelect mL(.weights(weights), .location(location), .selectedWeight(selectedWeight));
    outAssignerLL oLL(.write(write), .location(location), .curResult(f2Out), .resetn(resetn), .out(outREG));
    
    //biases
    multSelect biases(.weights(bias), .location(location), .selectedWeight(selectedBias));
    
    FPUnit f1(.clk(clk), .resetn(resetn), .operation(2'b10), .firstOp(copyIn), .secondOp(selectedWeight),
     .start(multInit), .done(multDone), .finalRes(f1Out));//, .Om_out(Om_out));
    FPUnit f2(.clk(clk), .resetn(resetn), .operation(2'b00), .firstOp(curResult), .secondOp(selectedBias),
     .start(addInit), .done(addDone), .finalRes(f2Out), .Om_out(Om_out), .Xm_out(Xm_out), .Ym_out(Ym_out), .toShift_out(toShift_out));
    
endmodule

module outAssignerLL(
    input write,
    input [0:3] location,
    input [31:0] curResult,
    input resetn,
    output reg [31:0] out[0:9]
);
    always@(posedge write or negedge resetn)begin
        if(resetn==1'b0)begin
            out[0]<=32'b0;
            out[1]<=32'b0;
            out[2]<=32'b0;
            out[3]<=32'b0;
            out[4]<=32'b0;
            out[5]<=32'b0;
            out[6]<=32'b0;
            out[7]<=32'b0;
            out[8]<=32'b0;
            out[9]<=32'b0;
        end
        else begin
            case(location)
                4'b0000:begin
                    out[0]<=curResult;
                end
                4'b0001:begin
                    out[1]<=curResult;
                end
                4'b0010:begin
                    out[2]<=curResult;
                end
                4'b0011:begin
                    out[3]<=curResult;
                end
                4'b0100:begin
                    out[4]<=curResult;
                end
                4'b0101:begin
                    out[5]<=curResult;
                end
                4'b0110:begin
                    out[6]<=curResult;
                end
                4'b0111:begin
                    out[7]<=curResult;
                end
                4'b1000:begin
                    out[8]<=curResult;
                end
                4'b1001:begin
                    out[9]<=curResult;
                end
            endcase
        end
    end
endmodule

module multSelect(
    input [31:0] weights[0:9],
    input [3:0] location,
    output reg [31:0] selectedWeight
);
    always@(*)begin
        case(location)
            4'b0000:begin
                selectedWeight=weights[0];
            end
            4'b0001:begin
                selectedWeight=weights[1];
            end
            4'b0010:begin
                selectedWeight=weights[2];
            end
            4'b0011:begin
                selectedWeight=weights[3];
            end
            4'b0100:begin
                selectedWeight=weights[4];
            end
            4'b0101:begin
                selectedWeight=weights[5];
            end
            4'b0110:begin
                selectedWeight=weights[6];
            end
            4'b0111:begin
                selectedWeight=weights[7];
            end
            4'b1000:begin
                selectedWeight=weights[8];
            end
            4'b1001:begin
                selectedWeight=weights[9];
            end
        endcase
    end
endmodule