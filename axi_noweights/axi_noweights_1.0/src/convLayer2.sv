`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 02/21/2022 09:39:14 PM
// Design Name: 
// Module Name: convLayer1
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////
//so my k is 7, my step is 7, and the size of my image is 28x28
//the output might need to be larger than what I have here in case the weights blow up
//that's not really an issue for me atm since I know the weights are small
//but if we ever move to something more advanced we will probably need to care about this
//these module declarations are sketchy as fuck atm
module conv_2(
        input clk,
        input resetn,
        input startFlag,
        input [31:0] in[0:3][0:3],
        input [31:0] win [0:1][0:1],
        input readyNext,
        output initShakeO,
        output handOff,
        output [31:0] out[0:1][0:1]
        
        //debug

    );
    
    //the conv mul/convadd/done states are for if/when the real floating point thing is implemented, they won't be done immediately
    //so we need some way of waiting until the result comes out first
    //maybe an in-progress state needs to be added
    enum reg [3:0] {INITWAIT, INITHAND, CONVOP, CONVMUL, CONVMULDONE, CONVMULADD, CONVMULADDDONE, CONVADD, CONVADDDONE, CONVOPDONE,
     WRITEOP, UPDATEWR, ASSIGNOUT, UPDATELOC, ENDWAIT, CLEANUP} STATES;
     //state and output reg
     //probably an intermediate reg too
    reg [3:0] curState;
    reg [3:0] nextState;
    reg [31:0] outREG [0:1][0:1];
    reg [31:0] interWeights[0:1][0:1];//2x2 kernal
    
    //outputs of floating point units
     reg [31:0] f1Out;
     reg [31:0] f2Out;
     reg [31:0] f3Out;
    /*initial begin
        interWeights[0]='{2{32'h3F800000}};
        interWeights[1]='{2{32'h40000000}};
    end*/
    
    always @ (posedge clk) begin
        interWeights = win;
    end
    
    //debug
    
    //the conv area stuff
    reg [31:0] tempConvArea[0:1][0:1];
    reg [31:0] convArea[0:1][0:1];
    //gonna hope everyone fits in this, this is the total for all the bits and shit seen so far
    reg [31:0] runningTotal;
    //the things to do with multiplying
    reg [31:0] tempMultValue;//size?
    reg [31:0] multConv;
    reg [31:0] multWeights;
    //for testing only, remove afterTODO IAN REMEMBER
    //initial begin
    //    multConv<=1'b1;
    //    multWeights<=1'b1;
    //end
    //location registers cause idk whyere I am
    //in layer two this can probably be about the same
    reg [1:0] writingToX;
    reg [1:0] writingToY;
    //which values am I multiplying?
    reg [2:0] calculatingWithX;
    reg [2:0] calculatingWithY;
    
    //these are proxys for signals I think might exist in the future
    //but do not currently exist now
    wire multDone;
    wire convAddDone;
    wire addDone;
    wire handShook;
    //assigning shit so that fsm goes
    //assign handShook=1'b1;
    /////assign addDone=1'b1;
    /////assign convAddDone=1'b1;
    /////assign multDone=1'b1;
    //setting output
    assign out=outREG;
    
    //control signals
    reg initShake;
    reg convInit;
    reg convMul;
    reg convMulDone;
    reg convBadd;
    reg convBaddDone;
    reg runningAdd;
    reg runningAddDone;
    reg assignOut;//maybe this gives some module outside of the datapath the signal to take in the value?
    reg incrementLoc;
    reg simpleIncrement;
    reg clean;
    //realistically this should be an output signal but I'll worry about that once I start making the other layers
    //in fact all handshake signals should be outputs, they'll just do nothing in the datapath for now
    reg endShake;
    //my handshake signals
    assign handOff=endShake;
    assign initShakeO=initShake;
    //controlPath
    always@(posedge clk)begin
        //set all my signals to 0 here, not that I have any atm
        initShake=1'b0;
        convInit=1'b0;
        convMul=1'b0;
        convMulDone=1'b0;
        convBadd=1'b0;
        convBaddDone=1'b0;
        runningAdd=1'b0;
        runningAddDone=1'b0;
        incrementLoc=1'b0;
        endShake=1'b0;
        simpleIncrement=1'b0;
        assignOut=1'b0;
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
                    //just spins unless it gets the go ahead to read some shit
                    //maybe continously sets the values to zero in wait for the next thing
                    if(startFlag==1'b1)begin
                        nextState=INITHAND;
                    end
                    else begin
                        nextState=curState;
                    end
                end
                INITHAND:begin
                    //gets the data and moves on to the next section
                    //this might need another exit case for the real thing, idk how long the in messages will be
                    //if so and I'm using axi to interface this maybe like get a signal from the top saying that it's done
                    //while acking the shit given to it
                    //set some handshake signal here
                    initShake=1'b1;
                    nextState=CONVOP;
                end
                CONVOP:begin
                    //send the data to the multiplier, probably more
                    //for now a single cycle, maybe more later
                    convInit=1'b1;
                    nextState=CONVMUL;
                end
                CONVMUL: begin
                    //multiply thing, fill into some temp reg, will get added to bigger thing later
                    //initializes multiply
                    convMul=1'b1;
                    nextState=CONVMULDONE;
                end
                CONVMULDONE: begin
                    //add the b value? Send some signals? This state might need to exist idk
                    //maybe it checks if it's done or not, stays here if not
                        if(multDone==1'b0)begin
                            //IF NOT DONE, take thing as input or wire idk
                            nextState=CONVMULDONE;
                        end
                        else begin
                            convMulDone=1'b1;
                            nextState=CONVMULADD;
                        end
                end
                CONVMULADD: begin
                    //added temp reg to running avg reg
                    //this might be the same sorta state as CONVADD, like it exists in case we do floating point
                    //initializes the add
                    convBadd=1'b1;
                    nextState=CONVMULADDDONE;   
                end
                CONVMULADDDONE: begin
                    if(convAddDone==1'b0)begin
                        nextState=CONVMULADDDONE;
                    end
                    else begin
                        convBaddDone=1'b1;
                        nextState=CONVADD;
                    end
                end
                CONVADD: begin
                    //initiates add to final res (is even needed? IDK)
                    runningAdd=1'b1;
                    nextState=CONVADDDONE;
                end
                CONVADDDONE: begin
                    //maybe not needed
                    if(addDone==1'b0)begin
                        nextState=CONVADDDONE;
                    end
                    else begin
                        runningAddDone=1'b1;
                        nextState=CONVOPDONE;
                    end
                end
                CONVOPDONE:begin
                    //maybe not needed, now here I do....... something........ since I don't know I'm just going to the next state
                    nextState=WRITEOP;
                end
                WRITEOP:begin
                    //write the just computed value into what will one day become the output matrix
                    //I don't think I need to perform any arithmetic, just kinda shove it in
                    nextState=UPDATEWR;
                end
                UPDATEWR:begin
                    //update the point we are trying to compute from/write to
                    //if full/done, move to ENDWAIT
                    if(calculatingWithX==3'b001 && calculatingWithY==3'b001) begin
                        //I am not done but I have to write the current thing
                        nextState=ASSIGNOUT;
                    end
                    else begin
                        //set signal to increment shit to datapath, go back to convop
                        //this is increment Writing loc
                        simpleIncrement=1'b1;
                        nextState=CONVOP;
                    end
                end
                ASSIGNOUT: begin
                    //so this state basically just exists to assign the out values
                    assignOut=1'b1;
                    if(writingToX==2'b01 && writingToY==2'b01) begin
                        nextState=ENDWAIT;
                    end
                    else begin
                        nextState=UPDATELOC;
                    end
                end
                UPDATELOC: begin
                    //change the location pointer thingies and go back to CONVOP
                    //make sure to reset the running total too
                    incrementLoc=1'b1;
                    nextState=CONVOP;
                end
                ENDWAIT:begin
                    //wait for handshake from next layer saying they got my shit, then leave back to spinning in init state
                    //assert some signal here saying I'm waiting for someone else to be done
                    //I think I need another state before this, like one where 
                    //maybe send to some sort of cleanup state and then back to wait?
                    //cause rn there's just a bunch of shit lying around from the prev run
                    //like send a signal that acts as a sorta ~global~ reset or something
                    if(readyNext==1'b1)begin
                        nextState=CLEANUP;
                    end
                    else begin
                        endShake=1'b1;
                        nextState=ENDWAIT;
                    end
                end
                //make cleanup state here
                CLEANUP:begin
                    clean=1'b1;
                    nextState=INITWAIT;
                end
                default:begin
                    //be very mad, say swear words, idk
                    nextState=INITWAIT;
                end
            endcase
        end
    end
    //temp thing for testing
    always@(negedge clk)begin
        if(resetn==1'b0)begin
            writingToX<=2'b00;
            writingToY<=2'b00;
            calculatingWithX<=3'b000;
            calculatingWithY<=3'b000;
            tempMultValue<=32'b0;
            runningTotal<=32'b0;
            //multWeights<=32'd1;
            //multConv<=32'd1;
        end
        else begin
            //da datapath
            //outREG[0][0]<=outREG[0][0]+1'b1;
            if(convInit)begin
                //move/set the layers to be operated on into some reg thing, I wonder if there is a better way
                //this basically goes down entirely in a module cause it's very big
                convArea<=tempConvArea;
            end
            
            if(convMulDone)begin
                tempMultValue<=f1Out;
            end
            if(convBaddDone)begin
                tempMultValue<=f2Out;
            end
            if(runningAddDone)begin
                runningTotal<=f3Out;
            end
            
            
            if(convMul)begin
                //simply multiply the two values
                //of course you'd have to find them too but that also goes down entirely in another module because it's very big
                /////tempMultValue<=multConv*multWeights;
            end
            if(convBadd)begin
                //well if I had a b to add here I'd do it but like
                //I haven't bothered to make one yet, but for our nn there is only 1 on this layer anyways so like
                //I'll just make something up later, or add 5 now
                /////tempMultValue<=tempMultValue+3'b101;
            end
            if(runningAdd)begin
                /////runningTotal<=runningTotal+tempMultValue;
            end
            if(simpleIncrement)begin
                if(calculatingWithX<3'b001) begin
                        calculatingWithX<=calculatingWithX+1'b1;
                    end
                else begin
                        calculatingWithX<=3'b000;
                        calculatingWithY<=calculatingWithY+1'b1;
                end
            end
            if(incrementLoc)begin
                //I have to increment the actual locations
                //and reset the running total
                runningTotal<=32'b0;
                calculatingWithX<=3'b000;
                calculatingWithY<=3'b000;
                if(writingToX<2'b01) begin
                    writingToX<=writingToX+1'b1;
                end
                else begin
                    //would/maybe should check if Y is already 11, but I shouldn't get the signal to go here if it is
                    writingToX<=2'b00;
                    writingToY<=writingToY+1'b1;
                end
            end
            if(clean)begin
                writingToX<=2'b00;
                writingToY<=2'b00;
                calculatingWithX<=3'b000;
                calculatingWithY<=3'b000;
                tempMultValue<=32'b0;
                runningTotal<=32'b0;
            end
        end
    end
    //other module instantiations
    blockFinderC2 b2(.totalImage(in), .writingToX(writingToX), .writingToY(writingToY), .currentBlock(tempConvArea));
    outAssignerC2 a2(.assignOut(assignOut), .writingToX(writingToX), .writingToY(writingToY), .runningTotal(runningTotal), .resetn(resetn), .out(outREG));
    multiFinderC2 m2(.calculatingWithX(calculatingWithX), .calculatingWithY(calculatingWithY), .curArea(convArea), .weights(interWeights), .toBeMultW(multWeights),
     .toBeMultA(multConv));
     
     
    FPUnit f1(.clk(clk), .resetn(resetn), .operation(2'b10), .firstOp(multConv), .secondOp(multWeights), .start(convMul), .done(multDone), .finalRes(f1Out));
    //always adding
    FPUnit f2(.clk(clk), .resetn(resetn), .operation(2'b00), .firstOp(tempMultValue), .secondOp(32'b0), .start(convBadd),
         .done(convAddDone), .finalRes(f2Out));
    //always adding
    FPUnit f3(.clk(clk), .resetn(resetn), .operation(2'b00), .firstOp(tempMultValue), .secondOp(runningTotal), .start(runningAdd),
         .done(addDone), .finalRes(f3Out));
     
endmodule

//the big unknown here is that I'm not super sure which weights correspond to which writing parts
//this shouldn't be too big of a deal to fix later though, as long as I can flip them fairly easily later, which I think I can

module outAssignerC2(
    input assignOut,
    input [1:0] writingToX, 
    input [1:0] writingToY,
    input [31:0] runningTotal,
    input resetn,
    output reg [31:0] out[0:1][0:1]
);
//when it goes high assign what's been computed so far to the right part of the output
//scuffed async reset here
    always@(posedge assignOut or negedge resetn)begin
        if(resetn==1'b0) begin
            out[0][0]<=32'b0;
            out[0][1]<=32'b0;
            out[1][0]<=32'b0;
            out[1][1]<=32'b0;
        end
        else begin
            if(runningTotal[31] == 1'b0) begin
                case({writingToX, writingToY})
                    4'b0000:begin
                        out[0][0]<=runningTotal;
                    end
                    4'b0001:begin
                        out[0][1]<=runningTotal;
                    end
                    4'b0100:begin
                        out[1][0]<=runningTotal;
                    end
                    4'b0101:begin
                        out[1][1]<=runningTotal;
                    end
                endcase
            end
            else begin
                case({writingToX, writingToY})
                    4'b0000:begin
                        out[0][0]<=32'b00000000000000000000000000000000;
                    end
                    4'b0001:begin
                        out[0][1]<=32'b00000000000000000000000000000000;
                    end
                    4'b0100:begin
                        out[1][0]<=32'b00000000000000000000000000000000;
                    end
                    4'b0101:begin
                        out[1][1]<=32'b00000000000000000000000000000000;
                    end
                endcase
            end
        end
    end
endmodule

module multiFinderC2(
    input [2:0] calculatingWithX,
    input [2:0] calculatingWithY,
    input [31:0] curArea[0:1][0:1],
    input [31:0] weights[0:1][0:1],
    output reg [31:0] toBeMultW,
    output reg [31:0] toBeMultA
);
    //to be completed
    //use two always blocks and an intermediate result cause I have way more cases now
    reg [31:0] interW[0:1];
    reg [31:0] interA[0:1];
    always@(*) begin
        //toBeMultW<=32'd1;
        //get the x part isolated
        if(calculatingWithX==3'b000)begin
            interW<=weights[0];
            interA<=curArea[0];
        end
        else if(calculatingWithX==3'b001)begin
            interW<=weights[1];
            interA<=curArea[1];
        end
    end
    
    always@(*) begin
        //isolate the final numbers
        if(calculatingWithY==3'b000)begin
            toBeMultW<=interW[0];
            toBeMultA<=interA[0];
        end
        else if(calculatingWithY==3'b001)begin
            toBeMultW<=interW[1];
            toBeMultA<=interA[1];
        end
    end
endmodule

//output size must change
module blockFinderC2(
    input [31:0] totalImage[0:3][0:3], 
    input [1:0] writingToX, 
    input [1:0] writingToY,
    output reg [31:0] currentBlock[0:1][0:1]
);
    always@(*)begin
        case({writingToX, writingToY})
            4'b0000:begin
                currentBlock[0]<=totalImage[0][0:1];
                currentBlock[1]<=totalImage[1][0:1];
            end
            4'b0001:begin
                currentBlock[0]<=totalImage[0][2:3];
                currentBlock[1]<=totalImage[1][2:3];
            end
            4'b0100:begin
                currentBlock[0]<=totalImage[2][0:1];
                currentBlock[1]<=totalImage[3][0:1];
            end
            4'b0101:begin
                currentBlock[0]<=totalImage[2][2:3];
                currentBlock[1]<=totalImage[3][2:3];
            end
            //default one day
        endcase
    end
endmodule
