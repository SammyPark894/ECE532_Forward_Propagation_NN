`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 02/21/2022 09:07:53 PM
// Design Name: 
// Module Name: topLevel
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
//num of channels=1, num of classes=10
//self.conv_1 = objax.nn.Sequential([objax.nn.Conv2D(number_of_channels, nout=1, k=7, strides=7), objax.functional.relu])#num in, num out, kernal size
//self.conv_2 = objax.nn.Sequential([objax.nn.Conv2D(nin=1, nout=1, k=2, strides=2), objax.functional.relu])
//x = x.mean((2,3))
//self.linear = objax.nn.Linear(1, number_of_classes)
module topLevel(
    input clk,
    input resetn,
    input startFlag,
    input [31:0] picTest [0:27][0:27],
    input [31:0] con1_weight [0:6][0:6],
    input [31:0] con2_weight [0:1][0:1],
    input [31:0] lin_weight [0:9],
    output handOff,
    output reg [31:0] calc_out,
    
    //debug

    output [31:0] all_lin_out [0:9],
    
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
    //picTest might have to grow a little to look like the registers below
    //the outputs also are probably not entirely correct here
    reg [31:0] firstOut[0:3][0:3];
    reg [31:0] secondOut[0:1][0:1];
    reg [31:0] thirdOut;//ofc this will need to be bigger
    reg [31:0] fourthOut[0:9];//cause I got the classes
    
    //Debug
    reg [31:0] lin_bias_t;
    assign all_lin_out = fourthOut;
    
    
    //inter-layer comms for 1/2
    wire initO1;
    wire handOff12;
    wire readyNext21;//this is initO1 but as of now the other stuff doesn't really go anywhere
    
    //inter-layer comms for 2/3
    wire readyNext23;
    wire handOff23;
    wire readyNext32;
    
    //3/4
    wire handOff34;
    wire readyNext43;
    
    //4/5?
    wire readyNext54;
    wire handOff45;
    
    assign handOff = handOff45;
    
    reg [31:0] max;
    reg [31:0] max_num;
    always @ (posedge handOff45) begin
        max_num = 32'h9;
        max = fourthOut[9];
        for (int i =0; i < 9; i=i+1) begin
            if(max[31] != fourthOut[i][31] & fourthOut[i][31] == 0) begin
                max_num = i;
                max = fourthOut[i];
            end
            else if(max[31] == fourthOut[i][31] & fourthOut[i][31] == 0 & max[30:23] < fourthOut[i][30:23]) begin
                max_num = i;
                max = fourthOut[i];
            end
            else if(max[31] == fourthOut[i][31] & fourthOut[i][31] == 1 & max[30:23] > fourthOut[i][30:23]) begin
                max_num = i;
                max = fourthOut[i];
            end
            else if(max[31] == fourthOut[i][31] & fourthOut[i][31] == 0 & max[30:23] == fourthOut[i][30:23] & max[22:0] < fourthOut[i][22:0]) begin
                max_num = i;
                max = fourthOut[i];
            end
            else if(max[31] == fourthOut[i][31] & fourthOut[i][31] == 1 & max[30:23] == fourthOut[i][30:23] & max[22:0] > fourthOut[i][22:0]) begin
                max_num = i;
                max = fourthOut[i];
            end
            
        end
        calc_out = max_num;
    end
    
    //this is pipelineable, probably won't ever get to it but it is not only possible but sorta primed for this
    conv_1 c1(.clk(clk), .resetn(resetn), .startFlag(startFlag), .in(picTest), .win(con1_weight), .readyNext(readyNext21), .initShakeO(initO1),
         .handOff(handOff12), .out(firstOut));
    conv_2 c2(.clk(clk), .resetn(resetn), .startFlag(handOff12), .in(firstOut), .win(con2_weight), .readyNext(readyNext32), .initShakeO(readyNext21),
     .handOff(handOff23), .out(secondOut));
    meanMod MM(.clk(clk), .resetn(resetn), .startFlag(handOff23), .in(secondOut), .readyNext(readyNext43), .initShakeO(readyNext32), 
      .handOff(handOff34), .out(thirdOut));
    linLay LL(.clk(clk), .resetn(resetn), .startFlag(handOff34), .in(thirdOut), .win(lin_weight), .readyNext(readyNext54), .initShakeO(readyNext43),
      .handOff(handOff45), .out(fourthOut),
      .copyIn_out(copyIn_out), .selectedWeight_out(selectedWeight_out), .f1Out_out(f1Out_out), 
      .curResult_out(curResult_out), .selectedBias_out(selectedBias_out), .f2Out_out(f2Out_out),
      .Om_out(Om_out),  .Xm_out(Xm_out), .Ym_out(Ym_out), .toShift_out(toShift_out));
endmodule
