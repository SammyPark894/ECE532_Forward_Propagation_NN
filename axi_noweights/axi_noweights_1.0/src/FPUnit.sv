`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 03/21/2022 07:32:16 PM
// Design Name: 
// Module Name: FPUnit
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

//this technically only supports add and multiply
//I'm assuming my endianness is right
module FPUnit(
    input clk,
    input resetn,
    input [1:0] operation,
    input [31:0] firstOp,
    input [31:0] secondOp,
    input start,
    output done,
    output [31:0] finalRes,
    
    //debug
    output [47:0] Om_out,
    output [46:0] Xm_out,
    output [46:0] Ym_out,
    
    output [7:0] toShift_out
    );
    
    //add is the same as sub, mult same as divide, or it matters for divide but I will cheat(is always 4, no need to do anything special, mess with exponent)
    //Xs*2^(Xe-Ye)*2^Ye where Xe=Ye
    enum reg [3:0] {INITWAIT, ADDEXPCHK, ADDSHIFTING, ADDACT, MULTOP, MULTEXP, NORM, ASSIGNOUTS, ZEROADD, ZEROMULT, DONE_WAIT, DONE} STATES;
    reg [3:0] curState;
    reg [3:0] nextState;
    
    //control flags
    reg addexpchk;
    reg addshifting;
    reg addact;
    reg norm;
    reg multop;
    reg multExp;
    reg assignOuts;
    reg zeroAdd;
    reg zeroMult;
    reg doneReg;
    
    //datapath signals
    //reg [22:0] mantDiff;
    reg whichX;//if 0 then X is the first op, if 1 then X is the second op
    reg matchingSigns;//if the signs don't match I will have to do some stuff that is different
    reg expInc;
    reg [7:0] toShift;
    reg [46:0] Xm;
    reg [46:0] Ym;
    reg [47:0] Om;//output mantissa
    reg [22:0] roundOm;
    
    reg [8:0] expInt;
    reg oSign;
    reg [7:0] oExp;
    //reg [46:0] mMant;
    
    //this is larger than it needs to be
    reg [7:0] expAdjust;
    //I belive these are the correct bits I want to bias and stuff here
    wire signed [7:0] unBiasedFirst;
    wire signed [7:0] unBiasedSecond;
    
    assign unBiasedFirst=firstOp[30:23]-7'b1111111;
    assign unBiasedSecond=secondOp[30:23]-7'b1111111;
    assign done=doneReg;
    assign finalRes={oSign, oExp, roundOm};//add Om[22] for rounding, this is prob not right for output
    
    //wire debug;
    assign Om_out = Om;
    assign Xm_out = Xm;
    assign Ym_out = Ym;
    assign toShift_out = toShift;
    
    //assign debug=(toShift!=0 && toShift>8'b00010111);
    //first make control path
    always@(posedge clk)begin
        if(resetn==1'b0)begin
            curState=INITWAIT;
            nextState=INITWAIT;
        end
        else begin
            curState=nextState;
            addexpchk=1'b0;
            addshifting=1'b0;
            addact=1'b0;
            norm=1'b0;
            multop=1'b0;
            multExp=1'b0;
            assignOuts=1'b0;
            zeroAdd=1'b0;
            zeroMult=1'b0;
            doneReg=1'b0;
            case(curState)
                INITWAIT:begin
                    //go into the add things
                    if(start==1'b1 && operation<2'b10 && !(firstOp==32'b0||secondOp==32'b0))begin
                        nextState=ADDEXPCHK;
                    end
                    else if(start==1'b1 && operation<2'b10 && (firstOp==32'b0||secondOp==32'b0))begin
                        nextState=ZEROADD;
                    end
                    else if(start==1'b1 && operation>=2'b10 && (firstOp==32'b0||secondOp==32'b0))begin
                        nextState=ZEROMULT;
                    end
                    else if(start==1'b1 && operation>=2'b10 && !(firstOp==32'b0||secondOp==32'b0))begin
                        nextState=MULTOP;
                    end
                    else begin
                        nextState=INITWAIT;
                    end
                end
                ADDEXPCHK:begin
                    //determine which is bigger then subtract smaller from bigger
                    //I'd also like to do the checking for subtraction here, decide who is bigger and set the thing accordingly
                    addexpchk=1'b1;
                    nextState=ADDSHIFTING;
                end
                ADDSHIFTING:begin
                    //this may cycle for a while if I try to shift to match one at a time
                    if(toShift==8'b0)begin
                        nextState=ADDACT;
                    end
                    else begin
                        addshifting=1'b1;
                        nextState=ADDSHIFTING;
                    end
                end
                ADDACT:begin
                    addact=1'b1;
                    nextState=NORM;
                end
                MULTOP:begin
                    multop=1'b1;
                    nextState=MULTEXP;
                end
                MULTEXP:begin
                    multExp=1'b1;
                    nextState=NORM;
                end
                NORM:begin
                    if(Om==48'b0||(Om[47]==1'b0&&Om[46]==1'b1))begin
                        nextState=ASSIGNOUTS;
                    end
                    else begin
                        norm=1'b1; 
                        nextState=NORM; 
                    end
                end
                ASSIGNOUTS:begin
                    assignOuts=1'b1;
                    nextState=DONE_WAIT;
                end
                ZEROADD:begin
                    zeroAdd=1'b1;
                    nextState=DONE_WAIT;
                end
                ZEROMULT:begin
                    zeroMult=1'b1;
                    nextState=DONE_WAIT;
                end
                DONE_WAIT: begin
                    nextState=DONE;
                end
                DONE:begin
                    doneReg=1'b1;
                    nextState=INITWAIT;
                end
            endcase
        end
    end
    
    //now for the datapath
    always@(negedge clk)begin
        if(resetn==1'b0)begin
            //reset all the shit, nothing for done
            whichX=1'b0;
            toShift=8'b0;
            Xm=47'b0;
            Ym=47'b0;
            Om=48'b0;
            oSign=1'b0;
            oExp=8'b0;
            roundOm=23'b0;
            expInc=1'b0;
            expAdjust=8'b0;
            expInt=9'b0;
            matchingSigns=1'b0;
        end
        else begin
            if(addexpchk)begin
                //find which is bigger in magnitude
                if(unBiasedFirst<unBiasedSecond)begin
                    oExp=secondOp[30:23];
                    oSign=secondOp[31];
                    toShift=(unBiasedSecond-unBiasedFirst);
                    Xm={1'b1, firstOp[22:0], 23'b0};
                    Ym={1'b1, secondOp[22:0], 23'b0};
                    if(firstOp[31]!=secondOp[31])begin
                        matchingSigns=1'b0;
                    end
                    else begin
                        matchingSigns=1'b1;
                    end
                end
                else if(unBiasedSecond<unBiasedFirst)begin
                    oExp=firstOp[30:23];
                    oSign=firstOp[31];
                    toShift=(unBiasedFirst-unBiasedSecond);
                    Xm={1'b1, secondOp[22:0], 23'b0};
                    Ym={1'b1, firstOp[22:0], 23'b0};
                    if(firstOp[31]!=secondOp[31])begin
                        matchingSigns=1'b0;
                    end
                    else begin
                        matchingSigns=1'b1;
                    end
                end
                else begin
                    if(firstOp[22:0]<secondOp[22:0])begin
                        oExp=secondOp[30:23];
                        oSign=secondOp[31];
                        toShift=(unBiasedSecond-unBiasedFirst);
                        Xm={1'b1, firstOp[22:0], 23'b0};
                        Ym={1'b1, secondOp[22:0], 23'b0};
                        if(firstOp[31]!=secondOp[31])begin
                            matchingSigns=1'b0;
                        end
                        else begin
                            matchingSigns=1'b1;
                        end
                    end
                    else if(secondOp[22:0]<firstOp[22:0]) begin
                        oExp=firstOp[30:23];
                        oSign=firstOp[31];
                        toShift=(unBiasedFirst-unBiasedSecond);
                        Xm={1'b1, secondOp[22:0], 23'b0};
                        Ym={1'b1, firstOp[22:0], 23'b0};
                        if(firstOp[31]!=secondOp[31])begin
                            matchingSigns=1'b0;
                        end
                        else begin
                            matchingSigns=1'b1;
                        end
                    end
                    else begin
                        //these numbers are equal just pick one
                        //oExp=firstOp[30:23];
                        toShift=(unBiasedFirst-unBiasedSecond);
                        Xm={1'b1, secondOp[22:0], 23'b0};
                        Ym={1'b1, firstOp[22:0], 23'b0};
                        if(firstOp[31]!=secondOp[31])begin
                            oSign=1'b0;
                            oExp=8'b0;
                            matchingSigns=1'b0;
                        end
                        else begin
                            matchingSigns=1'b1;
                            oExp=firstOp[30:23];
                            oSign=firstOp[31];
                        end
                    end
                end
                Xm=Xm>>toShift;
                toShift=8'b0;
            end
            else if(addshifting)begin
                //I could do this in one cycle with a big case statement but it will be very very large and a nightmare to write
                //or I could cheat a little, if I shift more than 23 it is 0
                //for now I will do a single shift at a time
                if(toShift!=0 && toShift<8'b00010111)begin
                    Xm=Xm>>1'b1;
                    toShift=toShift-1'b1;
                end
                else begin
                    //if far off we go to 0
                    Xm=47'b0;
                    toShift=8'b0;
                end
            end
            else if(addact)begin
                //add the mantissas if signs match, subtract otherwise
                if(matchingSigns)begin
                    Om=Ym+Xm;
                end
                else begin
                    Om=Ym-Xm;
                end
            end
            else if(multop)begin
                //take only the top 23 of mMant
                oSign=firstOp[31]^secondOp[31];
                //this overflows sometimes and cannot be directly assigned
                expInt=(firstOp[30:23]+secondOp[30:23]);//do the minus here to get the correct mantissa, added bias twice otherwise
                Om={1'b1, firstOp[22:0]}*{1'b1, secondOp[22:0]};//I forgot the leading 1 and shit, holy shit
            end
            else if(multExp)begin
                oExp=expInt-7'b1111111;
            end
            else if(norm)begin
                //something has to happen here. maybe add a state for moving result into registers
                //if the leading digit is not a 1 keep doing the shift until it is, keep count and add to exponent
                //can also be done in a single cycle if I want to
                if(Om[47]!=1'b1 && Om[46]!=1'b1)begin
                    Om=Om<<1;
                    expAdjust=expAdjust+1'b1;
                end
                else begin
                    if(Om[47]==1'b1)begin
                        //expInc=1'b1;
                        oExp=oExp+8'b1;
                        Om=Om>>1;
                    end
                    else if(Om[46]==1'b1)begin
                        expInc=1'b0;
                    end
                end
            end
            else if(assignOuts)begin
                //Get the exponent right and round right (subtract, add, based on sign thing?)
                oExp=oExp-expAdjust;//+expInc;
                roundOm=Om[45:23]+Om[22];
            end
            else if(zeroAdd)begin
                //find which is zero and assign out to be the in of the other
                if(firstOp==32'b0)begin
                    oExp=secondOp[30:23];
                    oSign=secondOp[31];
                    roundOm=secondOp[22:0];
                end
                else begin
                    //if they are both zero this will still give 0 out
                    oExp=firstOp[30:23];
                    oSign=firstOp[31];
                    roundOm=firstOp[22:0];
                end
            end
            else if(zeroMult)begin
                //make out zero
                oExp=8'b0;
                roundOm=23'b0;
                oSign=1'b0;
            end
            else if(done)begin
                //clean up everything but the output registers
                whichX=1'b0;
                toShift=8'b0;
                Xm=47'b0;
                Ym=47'b0;
                Om=48'b0;
                expInc=1'b0;
                expAdjust=8'b0;
                expInt=9'b0;
                matchingSigns=1'b0;
            end
            
        end
    end 
endmodule


//make something that works first then optimize
//module shiftIt(
//   
//);
//endmodule
