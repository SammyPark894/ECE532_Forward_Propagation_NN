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
module conv_1(
        input clk,
        input resetn,
        input startFlag,
        input [31:0] in [0:27][0:27],
        input [31:0] win [0:6][0:6],
        input readyNext,
        output initShakeO,
        output handOff,
        output [31:0] out[0:3][0:3]
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
    reg [31:0] outREG [0:3][0:3];
    reg [31:0] interWeights[0:6][0:6];
    
     //outputs of floating point units
     reg [31:0] f1Out;
     reg [31:0] f2Out;
     reg [31:0] f3Out;
    /*initial begin
        interWeights[0]='{7{32'h3F800000}};
        interWeights[1]='{7{32'h40000000}};
        interWeights[2]='{7{32'h40400000}};
        interWeights[3]='{7{32'h40800000}};
        interWeights[4]='{7{32'h40A00000}};
        interWeights[5]='{7{32'h40C00000}};
        interWeights[6]='{7{32'h40E00000}};
    end*/
    
    reg [31:0] picForTesting[0:27][0:27];
    
    always @ (posedge clk) begin
        picForTesting = in;
        interWeights = win;
    end

    /*initial begin
        //make it all ones, should be easy to calculate then
        integer i;
        for(i=0;i<28;i=i+1)begin
            picForTesting[i]='{28{32'h3F800000}};
        end
    end*/
    //the conv area stuff
    reg [31:0] tempConvArea[0:6][0:6];
    reg [31:0] convArea[0:6][0:6];
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
    
    //these should be assigned to each respective floating point unit
    //////assign addDone=1'b1;
    //////assign convAddDone=1'b1;
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
                            //add signal here, if done assign out
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
                        //add signal here, if done assign out
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
                        //add signal here, if done assign out
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
                    if(calculatingWithX==3'b110 && calculatingWithY==3'b110) begin
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
                    if(writingToX==2'b11 && writingToY==2'b11) begin
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
                //no change
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
                //remove/change this to assigning out upon finish
                //simply multiply the two values
                //of course you'd have to find them too but that also goes down entirely in another module because it's very big
                /////tempMultValue<=multConv*multWeights;
            end
            if(convBadd)begin
                //remove/change this to assigning out upon finish
                //well if I had a b to add here I'd do it but like
                //I haven't bothered to make one yet, but for our nn there is only 1 on this layer anyways so like
                //I'll just make something up later, or add 5 now
                //now must set the two inputs to the floating point unit here, or the FPU I'm using
                /////tempMultValue<=tempMultValue+3'b101;
            end
            if(runningAdd)begin
                //remove/change this to assigning out upon finish
                /////runningTotal<=runningTotal+tempMultValue;
            end
            
            
            
            if(simpleIncrement)begin
                if(calculatingWithX<3'b110) begin
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
                if(writingToX<2'b11) begin
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
    blockFinder b1(.totalImage(picForTesting), .writingToX(writingToX), .writingToY(writingToY), .currentBlock(tempConvArea));
    outAssigner a1(.assignOut(assignOut), .writingToX(writingToX), .writingToY(writingToY), .runningTotal(runningTotal), .resetn(resetn), .out(outREG));
    multiFinder m1(.calculatingWithX(calculatingWithX), .calculatingWithY(calculatingWithY), .curArea(convArea), .weights(interWeights), .toBeMultW(multWeights),
     .toBeMultA(multConv));
     
     //floating point unit instantiations
     //FPUnit f1(.clk(), .resetn(), .operation(), .firstOp(), .secondOp(), .start(), .done(), .finalRes());
     //always multiplying
     FPUnit f1(.clk(clk), .resetn(resetn), .operation(2'b10), .firstOp(multConv), .secondOp(multWeights), .start(convMul), .done(multDone), .finalRes(f1Out));
     //always adding
     FPUnit f2(.clk(clk), .resetn(resetn), .operation(2'b00), .firstOp(tempMultValue), .secondOp(32'b10111010001111110110110110010100), .start(convBadd),
         .done(convAddDone), .finalRes(f2Out));
     //always adding
     FPUnit f3(.clk(clk), .resetn(resetn), .operation(2'b00), .firstOp(tempMultValue), .secondOp(runningTotal), .start(runningAdd),
         .done(addDone), .finalRes(f3Out));
     
endmodule


module outAssigner(
    input assignOut,
    input [1:0] writingToX, 
    input [1:0] writingToY,
    input [31:0] runningTotal,
    input resetn,
    output reg [31:0] out[0:3][0:3]
);
//when it goes high assign what's been computed so far to the right part of the output
//scuffed async reset here
    always@(posedge assignOut or negedge resetn)begin
        if(resetn==1'b0) begin
            out[0][0]<=32'b0;
            out[0][1]<=32'b0;
            out[0][2]<=32'b0;
            out[0][3]<=32'b0;
            out[1][0]<=32'b0;
            out[1][1]<=32'b0;
            out[1][2]<=32'b0;
            out[1][3]<=32'b0;
            out[2][0]<=32'b0;
            out[2][1]<=32'b0;
            out[2][2]<=32'b0;
            out[2][3]<=32'b0;
            out[3][0]<=32'b0;
            out[3][1]<=32'b0;
            out[3][2]<=32'b0;
            out[3][3]<=32'b0;
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
                    4'b0010:begin
                        out[0][2]<=runningTotal;
                    end
                    4'b0011:begin
                        out[0][3]<=runningTotal;
                    end
                    4'b0100:begin
                        out[1][0]<=runningTotal;
                    end
                    4'b0101:begin
                        out[1][1]<=runningTotal;
                    end
                    4'b0110:begin
                        out[1][2]<=runningTotal;
                    end
                    4'b0111:begin
                        out[1][3]<=runningTotal;
                    end
                    4'b1000:begin
                        out[2][0]<=runningTotal;
                    end
                    4'b1001:begin
                        out[2][1]<=runningTotal;
                    end
                    4'b1010:begin
                        out[2][2]<=runningTotal;
                    end
                    4'b1011:begin
                        out[2][3]<=runningTotal;
                    end
                    4'b1100:begin
                        out[3][0]<=runningTotal;
                    end
                    4'b1101:begin
                        out[3][1]<=runningTotal;
                    end
                    4'b1110:begin
                        out[3][2]<=runningTotal;
                    end
                    4'b1111:begin
                        out[3][3]<=runningTotal;
                    end
                endcase
            end
            else begin
                case({writingToX, writingToY})
                    4'b0000:begin
                        out[0][0]<=32'b0;
                    end
                    4'b0001:begin
                        out[0][1]<=32'b0;
                    end
                    4'b0010:begin
                        out[0][2]<=32'b0;
                    end
                    4'b0011:begin
                        out[0][3]<=32'b0;
                    end
                    4'b0100:begin
                        out[1][0]<=32'b0;
                    end
                    4'b0101:begin
                        out[1][1]<=32'b0;
                    end
                    4'b0110:begin
                        out[1][2]<=32'b0;
                    end
                    4'b0111:begin
                        out[1][3]<=32'b0;
                    end
                    4'b1000:begin
                        out[2][0]<=32'b0;
                    end
                    4'b1001:begin
                        out[2][1]<=32'b0;
                    end
                    4'b1010:begin
                        out[2][2]<=32'b0;
                    end
                    4'b1011:begin
                        out[2][3]<=32'b0;
                    end
                    4'b1100:begin
                        out[3][0]<=32'b0;
                    end
                    4'b1101:begin
                        out[3][1]<=32'b0;
                    end
                    4'b1110:begin
                        out[3][2]<=32'b0;
                    end
                    4'b1111:begin
                        out[3][3]<=32'b0;
                    end
                endcase
            end
        end
    end
endmodule

module multiFinder(
    input [2:0] calculatingWithX,
    input [2:0] calculatingWithY,
    input [31:0] curArea[0:6][0:6],
    input [31:0] weights[0:6][0:6],
    output reg [31:0] toBeMultW,
    output reg [31:0] toBeMultA
);
    //to be completed
    //use two always blocks and an intermediate result cause I have way more cases now
    reg [31:0] interW[0:6];
    reg [31:0] interA[0:6];
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
        else if(calculatingWithX==3'b010)begin
            interW<=weights[2];
            interA<=curArea[2];
        end
        else if(calculatingWithX==3'b011)begin
            interW<=weights[3];
            interA<=curArea[3];
        end
        else if(calculatingWithX==3'b100)begin
            interW<=weights[4];
            interA<=curArea[4];
        end
        else if(calculatingWithX==3'b101)begin
            interW<=weights[5];
            interA<=curArea[5];
        end
        else if(calculatingWithX==3'b110)begin
            interW<=weights[6];
            interA<=curArea[6];
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
        else if(calculatingWithY==3'b010)begin
            toBeMultW<=interW[2];
            toBeMultA<=interA[2];
        end
        else if(calculatingWithY==3'b011)begin
            toBeMultW<=interW[3];
            toBeMultA<=interA[3];
        end
        else if(calculatingWithY==3'b100)begin
            toBeMultW<=interW[4];
            toBeMultA<=interA[4];
        end
        else if(calculatingWithY==3'b101)begin
            toBeMultW<=interW[5];
            toBeMultA<=interA[5];
        end
        else if(calculatingWithY==3'b110)begin
            toBeMultW<=interW[6];
            toBeMultA<=interA[6];
        end
    end
endmodule

//this has to actually change
module blockFinder(
    input [31:0] totalImage[0:27][0:27], 
    input [1:0] writingToX, 
    input [1:0] writingToY,
    output reg [31:0] currentBlock[0:6][0:6]
);
    always@(*)begin
        case({writingToX, writingToY})
            4'b0000:begin
                currentBlock[0]<=totalImage[0][0:6];
                currentBlock[1]<=totalImage[1][0:6];
                currentBlock[2]<=totalImage[2][0:6];
                currentBlock[3]<=totalImage[3][0:6];
                currentBlock[4]<=totalImage[4][0:6];
                currentBlock[5]<=totalImage[5][0:6];
                currentBlock[6]<=totalImage[6][0:6];
            end
            4'b0001:begin
                currentBlock[0]<=totalImage[0][7:13];
                currentBlock[1]<=totalImage[1][7:13];
                currentBlock[2]<=totalImage[2][7:13];
                currentBlock[3]<=totalImage[3][7:13];
                currentBlock[4]<=totalImage[4][7:13];
                currentBlock[5]<=totalImage[5][7:13];
                currentBlock[6]<=totalImage[6][7:13];
            end
            4'b0010:begin
                currentBlock[0]<=totalImage[0][14:20];
                currentBlock[1]<=totalImage[1][14:20];
                currentBlock[2]<=totalImage[2][14:20];
                currentBlock[3]<=totalImage[3][14:20];
                currentBlock[4]<=totalImage[4][14:20];
                currentBlock[5]<=totalImage[5][14:20];
                currentBlock[6]<=totalImage[6][14:20];
            end
            4'b0011:begin
                currentBlock[0]<=totalImage[0][21:27];
                currentBlock[1]<=totalImage[1][21:27];
                currentBlock[2]<=totalImage[2][21:27];
                currentBlock[3]<=totalImage[3][21:27];
                currentBlock[4]<=totalImage[4][21:27];
                currentBlock[5]<=totalImage[5][21:27];
                currentBlock[6]<=totalImage[6][21:27];
            end
            4'b0100:begin
                currentBlock[0]<=totalImage[7][0:6];
                currentBlock[1]<=totalImage[8][0:6];
                currentBlock[2]<=totalImage[9][0:6];
                currentBlock[3]<=totalImage[10][0:6];
                currentBlock[4]<=totalImage[11][0:6];
                currentBlock[5]<=totalImage[12][0:6];
                currentBlock[6]<=totalImage[13][0:6];
            end
            4'b0101:begin
                currentBlock[0]<=totalImage[7][7:13];
                currentBlock[1]<=totalImage[8][7:13];
                currentBlock[2]<=totalImage[9][7:13];
                currentBlock[3]<=totalImage[10][7:13];
                currentBlock[4]<=totalImage[11][7:13];
                currentBlock[5]<=totalImage[12][7:13];
                currentBlock[6]<=totalImage[13][7:13];
            end
            4'b0110:begin
                currentBlock[0]<=totalImage[7][14:20];
                currentBlock[1]<=totalImage[8][14:20];
                currentBlock[2]<=totalImage[9][14:20];
                currentBlock[3]<=totalImage[10][14:20];
                currentBlock[4]<=totalImage[11][14:20];
                currentBlock[5]<=totalImage[12][14:20];
                currentBlock[6]<=totalImage[13][14:20];
            end
            4'b0111:begin
                currentBlock[0]<=totalImage[7][21:27];
                currentBlock[1]<=totalImage[8][21:27];
                currentBlock[2]<=totalImage[9][21:27];
                currentBlock[3]<=totalImage[10][21:27];
                currentBlock[4]<=totalImage[11][21:27];
                currentBlock[5]<=totalImage[12][21:27];
                currentBlock[6]<=totalImage[13][21:27];        
            end
            4'b1000:begin
                currentBlock[0]<=totalImage[14][0:6];
                currentBlock[1]<=totalImage[15][0:6];
                currentBlock[2]<=totalImage[16][0:6];
                currentBlock[3]<=totalImage[17][0:6];
                currentBlock[4]<=totalImage[18][0:6];
                currentBlock[5]<=totalImage[19][0:6];
                currentBlock[6]<=totalImage[20][0:6];      
            end
            4'b1001:begin
                currentBlock[0]<=totalImage[14][7:13];
                currentBlock[1]<=totalImage[15][7:13];
                currentBlock[2]<=totalImage[16][7:13];
                currentBlock[3]<=totalImage[17][7:13];
                currentBlock[4]<=totalImage[18][7:13];
                currentBlock[5]<=totalImage[19][7:13];
                currentBlock[6]<=totalImage[20][7:13];           
            end
            4'b1010:begin
                currentBlock[0]<=totalImage[14][14:20];
                currentBlock[1]<=totalImage[15][14:20];
                currentBlock[2]<=totalImage[16][14:20];
                currentBlock[3]<=totalImage[17][14:20];
                currentBlock[4]<=totalImage[18][14:20];
                currentBlock[5]<=totalImage[19][14:20];
                currentBlock[6]<=totalImage[20][14:20];                
            end
            4'b1011:begin
                currentBlock[0]<=totalImage[14][21:27];
                currentBlock[1]<=totalImage[15][21:27];
                currentBlock[2]<=totalImage[16][21:27];
                currentBlock[3]<=totalImage[17][21:27];
                currentBlock[4]<=totalImage[18][21:27];
                currentBlock[5]<=totalImage[19][21:27];
                currentBlock[6]<=totalImage[20][21:27];             
            end
            4'b1100:begin
                currentBlock[0]<=totalImage[21][0:6];
                currentBlock[1]<=totalImage[22][0:6];
                currentBlock[2]<=totalImage[23][0:6];
                currentBlock[3]<=totalImage[24][0:6];
                currentBlock[4]<=totalImage[25][0:6];
                currentBlock[5]<=totalImage[26][0:6];
                currentBlock[6]<=totalImage[27][0:6];         
            end
            4'b1101:begin
                currentBlock[0]<=totalImage[21][7:13];
                currentBlock[1]<=totalImage[22][7:13];
                currentBlock[2]<=totalImage[23][7:13];
                currentBlock[3]<=totalImage[24][7:13];
                currentBlock[4]<=totalImage[25][7:13];
                currentBlock[5]<=totalImage[26][7:13];
                currentBlock[6]<=totalImage[27][7:13];  
            end
            4'b1110:begin
                currentBlock[0]<=totalImage[21][14:20];
                currentBlock[1]<=totalImage[22][14:20];
                currentBlock[2]<=totalImage[23][14:20];
                currentBlock[3]<=totalImage[24][14:20];
                currentBlock[4]<=totalImage[25][14:20];
                currentBlock[5]<=totalImage[26][14:20];
                currentBlock[6]<=totalImage[27][14:20];
            end
            4'b1111:begin
                currentBlock[0]<=totalImage[21][21:27];
                currentBlock[1]<=totalImage[22][21:27];
                currentBlock[2]<=totalImage[23][21:27];
                currentBlock[3]<=totalImage[24][21:27];
                currentBlock[4]<=totalImage[25][21:27];
                currentBlock[5]<=totalImage[26][21:27];
                currentBlock[6]<=totalImage[27][21:27];
            end
            //default one day
        endcase
    end
endmodule
