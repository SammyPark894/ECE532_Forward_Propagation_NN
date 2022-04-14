
`timescale 1 ns / 1 ps

	module second_top #
	(
		// Users to add parameters here

		// User parameters ends
		// Do not modify the parameters beyond this line


		// Parameters of Axi Slave Bus Interface S00_AXI
		parameter integer C_S00_AXI_DATA_WIDTH	= 32,
		parameter integer C_S00_AXI_ADDR_WIDTH	= 6
	)
	(
		// Users to add ports here

		// User ports ends
		// Do not modify the ports beyond this line


		// Ports of Axi Slave Bus Interface S00_AXI
		input wire  s00_axi_aclk,
		input wire  s00_axi_aresetn,
		input wire [C_S00_AXI_ADDR_WIDTH-1 : 0] s00_axi_awaddr,
		input wire [2 : 0] s00_axi_awprot,
		input wire  s00_axi_awvalid,
		output wire  s00_axi_awready,
		input wire [C_S00_AXI_DATA_WIDTH-1 : 0] s00_axi_wdata,
		input wire [(C_S00_AXI_DATA_WIDTH/8)-1 : 0] s00_axi_wstrb,
		input wire  s00_axi_wvalid,
		output wire  s00_axi_wready,
		output wire [1 : 0] s00_axi_bresp,
		output wire  s00_axi_bvalid,
		input wire  s00_axi_bready,
		input wire [C_S00_AXI_ADDR_WIDTH-1 : 0] s00_axi_araddr,
		input wire [2 : 0] s00_axi_arprot,
		input wire  s00_axi_arvalid,
		output wire  s00_axi_arready,
		output wire [C_S00_AXI_DATA_WIDTH-1 : 0] s00_axi_rdata,
		output wire [1 : 0] s00_axi_rresp,
		output wire  s00_axi_rvalid,
		input wire  s00_axi_rready,
		
		//seven seg part
		output reg [7:0] AN,
		output wire CA,
		output wire CB,
		output wire CC,
		output wire CD,
		output wire CE,
		output wire CF,
		output wire CG,
		
		output wire DP,
		
		//Debug with sys ILA
		//output wire [31:0] image_out,

		
		output wire [31:0] lin_out0,
		output wire [31:0] lin_out1,
		output wire [31:0] lin_out2,
		output wire [31:0] lin_out3,
		output wire [31:0] lin_out4,
		output wire [31:0] lin_out5,
		output wire [31:0] lin_out6,
		output wire [31:0] lin_out7,
		output wire [31:0] lin_out8,
		output wire [31:0] lin_out9,
		
		output wire [31:0] copyIn_out,
        output wire [31:0] selectedWeight_out,
        output wire [31:0] f1Out_out,
        
        output wire [31:0] curResult_out,
        output wire [31:0] selectedBias_out,
        output wire [31:0] f2Out_out,
        output wire [47:0] Om_out,
        output [46:0] Xm_out,
        output [46:0] Ym_out,
        output [7:0] toShift_out  
	);
// Instantiation of Axi Bus Interface S00_AXI
	axi_noweights_v1_0_S00_AXI # ( 
		.C_S_AXI_DATA_WIDTH(C_S00_AXI_DATA_WIDTH),
		.C_S_AXI_ADDR_WIDTH(C_S00_AXI_ADDR_WIDTH)
	) axi_noweights_v1_0_S00_AXI_inst (
		.S_AXI_ACLK(s00_axi_aclk),
		.S_AXI_ARESETN(s00_axi_aresetn),
		.S_AXI_AWADDR(s00_axi_awaddr),
		.S_AXI_AWPROT(s00_axi_awprot),
		.S_AXI_AWVALID(s00_axi_awvalid),
		.S_AXI_AWREADY(s00_axi_awready),
		.S_AXI_WDATA(s00_axi_wdata),
		.S_AXI_WSTRB(s00_axi_wstrb),
		.S_AXI_WVALID(s00_axi_wvalid),
		.S_AXI_WREADY(s00_axi_wready),
		.S_AXI_BRESP(s00_axi_bresp),
		.S_AXI_BVALID(s00_axi_bvalid),
		.S_AXI_BREADY(s00_axi_bready),
		.S_AXI_ARADDR(s00_axi_araddr),
		.S_AXI_ARPROT(s00_axi_arprot),
		.S_AXI_ARVALID(s00_axi_arvalid),
		.S_AXI_ARREADY(s00_axi_arready),
		.S_AXI_RDATA(s00_axi_rdata),
		.S_AXI_RRESP(s00_axi_rresp),
		.S_AXI_RVALID(s00_axi_rvalid),
		.S_AXI_RREADY(s00_axi_rready),
		//User added ports begin
		.DATA_OUT(data_in),
		.ROW_OUT(row_in),
		.COL_OUT(col_in),
		.IMAGE_WEN_OUT(image_wen),
		.W0_WEN_OUT(conv1_wen),
		.W1_WEN_OUT(conv2_wen),
		.W2_WEN_OUT(lin_wen),
		.W3_WEN_OUT(w3_wen),
		.FINAL_IN(final_out),
		.START_CAL_OUT(start_cal_in),
		.DONE_IN(done_out),
		.READY_IN(ready_out)
		//User added ports end
		
	);

	// Add user logic here
    wire [C_S00_AXI_DATA_WIDTH-1:0]	data_in;
    wire [C_S00_AXI_DATA_WIDTH-1:0]	row_in;
    wire [C_S00_AXI_DATA_WIDTH-1:0] col_in;
    wire image_wen;
    wire conv1_wen;
    wire conv2_wen;
    wire lin_wen;
    wire w3_wen;
    wire start_cal_in;
    
    reg [31:0] all_lin_out [0:9];
    
    assign lin_out0 = all_lin_out[0];
    assign lin_out1 = all_lin_out[1];
    assign lin_out2 = all_lin_out[2];
    assign lin_out3 = all_lin_out[3];
    assign lin_out4 = all_lin_out[4];
    assign lin_out5 = all_lin_out[5];
    assign lin_out6 = all_lin_out[6];
    assign lin_out7 = all_lin_out[7];
    assign lin_out8 = all_lin_out[8];
    assign lin_out9 = all_lin_out[9];
    // ports of the NN module
    reg clean_resetn;
    
    wire calc_done;
    wire [C_S00_AXI_DATA_WIDTH-1:0] calc_in;
    wire [C_S00_AXI_DATA_WIDTH-1:0] image_out [0:27][0:27];
    
    
    assign clk = s00_axi_aclk;
    assign resetn = s00_axi_aresetn & clean_resetn;
    
    reg [C_S00_AXI_DATA_WIDTH-1:0] image [0:27][0:27];
    reg [C_S00_AXI_DATA_WIDTH-1:0] conv1_weight[0:6][0:6];
    reg [C_S00_AXI_DATA_WIDTH-1:0] conv2_weight[0:1][0:1];
    reg [C_S00_AXI_DATA_WIDTH-1:0] lin_weight[0:9];
    
    reg done_out;
    reg ready_out;
    reg [C_S00_AXI_DATA_WIDTH-1:0] final_out;
    

    //assign image_out = image;
    
    //simple finite state machine parameters
    reg [2:0] state;
    reg [2:0] next_state;
    parameter ready_s = 3'b000, img_write_s = 3'b001, calc_s = 3'b010, con1_write_s = 3'b011, con2_write_s = 3'b100, lin_write_s = 3'b101, done_clean_s = 3'b110; 
    
    assign image_out = image;
    topLevel top(.clk(clk), .resetn(resetn), .startFlag(start_cal_in), .picTest(image), .con1_weight(conv1_weight), .con2_weight(conv2_weight), 
                .lin_weight(lin_weight), .handOff(calc_done), .calc_out(calc_in),
                .all_lin_out(all_lin_out)
                , .copyIn_out(copyIn_out), .selectedWeight_out(selectedWeight_out), .f1Out_out(f1Out_out), .curResult_out(curResult_out), 
                .selectedBias_out(selectedBias_out), .f2Out_out(f2Out_out),
                .Om_out(Om_out),  .Xm_out(Xm_out), .Ym_out(Ym_out), .toShift_out(toShift_out));
    
    integer i, j;
	
	
	always @(posedge clk) begin
        if (state == ready_s)
        begin
            clean_resetn <= 1'b1;
            ready_out <= 1'b1;
            done_out <= 1'b0;
            final_out <= final_out;
        end
        
        if (state == img_write_s)
        begin
            image[row_in][col_in] <= data_in;
            clean_resetn <= 1'b1;
            ready_out <= 1'b0;
            done_out <= 1'b1;
            final_out <= 32'b0;
        end
        
        if (state == con1_write_s)
        begin
            conv1_weight[row_in][col_in] <= data_in;
            clean_resetn <= 1'b1;
            ready_out <= 1'b0;
            done_out <= 1'b1;
            final_out <= 32'b0;
        end
        
        if (state == con2_write_s)
        begin
            conv2_weight[row_in][col_in] <= data_in;
            clean_resetn <= 1'b1;
            ready_out <= 1'b0;
            done_out <= 1'b1;
            final_out <= 32'b0;
        end
        
        if (state == lin_write_s)
        begin
            lin_weight[row_in] <= data_in;
            clean_resetn <= 1'b1;
            ready_out <= 1'b0;
            done_out <= 1'b1;
            final_out <= 32'b0;
        end
        
        if (state == calc_s)
        begin
            clean_resetn <= 1'b1;
            ready_out <= 1'b0;
            done_out <= calc_done;
            final_out <= calc_in;
        end
        
        if (state == done_clean_s) begin
            clean_resetn <= 1'b0;
            ready_out <= 1'b0;
            done_out <= 1'b1;
            final_out  <= final_out;
        end
	end
	
	always @ (posedge clk) begin
		
		if (s00_axi_aresetn == 1'b0) begin
		    state = ready_s;
			next_state = ready_s;
		end
		else if (state == ready_s && image_wen == 1'b1)
				next_state = img_write_s;
		else if (state == ready_s && start_cal_in == 1'b1)
				next_state = calc_s;
	    else if (state == img_write_s && image_wen == 1'b0)
				next_state = ready_s;
				
		else if (state == ready_s && conv1_wen == 1'b1)
				next_state = con1_write_s;
		else if (state == ready_s && conv2_wen == 1'b1)
				next_state = con2_write_s;
		else if (state == ready_s && lin_wen == 1'b1)
				next_state = lin_write_s;
				
		
		else if (state == con1_write_s && conv1_wen == 1'b0)
				next_state = ready_s;
		else if (state == con2_write_s && conv2_wen == 1'b0)
				next_state = ready_s;
		else if (state == lin_write_s && lin_wen == 1'b0)
				next_state = ready_s;
		else if (state == calc_s && done_out == 1'b1)
		        next_state = done_clean_s;
		else if (state == done_clean_s && start_cal_in == 1'b0) 
				next_state = ready_s;
		else next_state = state;
		state = next_state;
	end
	
	reg [7:0] display;
	
	assign CA = display[0];
	assign CB = display[1];
	assign CC = display[2];
	assign CD = display[3];
	assign CE = display[4];
	assign CF = display[5];
	assign CG = display[6];
	
	
	always @ (*) begin
	   AN = 7'b1111110;
       if (final_out == 0) display = 7'b1000000;
       else if (final_out == 1) display = 7'b1111001;
       else if (final_out == 2) display = 7'b0100100;
       else if (final_out == 3) display = 7'b0110000;
       else if (final_out == 4) display = 7'b0011001;
       else if (final_out == 5) display = 7'b0010010;
       else if (final_out == 6) display = 7'b0000010;
       else if (final_out == 7) display = 7'b1111000;
       else if (final_out == 8) display = 7'b0000000;
       else if (final_out == 9) display = 7'b0010000;
   end
	
	
	// User logic ends
	endmodule
	
	module seven_seg(
	   input [32:0] num,
	   output reg [7:0] display
	   );
	   
	   always @ (*) begin
	       if (num == 0) display = 7'b1000000;
	       else if (num == 1) display = 7'b1111001;
	       else if (num == 2) display = 7'b0100100;
	       else if (num == 3) display = 7'b0110000;
	       else if (num == 4) display = 7'b0011001;
	       else if (num == 5) display = 7'b0010010;
	       else if (num == 6) display = 7'b0000010;
	       else if (num == 7) display = 7'b1111000;
	       else if (num == 8) display = 7'b0000000;
	       else if (num == 9) display = 7'b0010000;
	   end
	
	endmodule
	