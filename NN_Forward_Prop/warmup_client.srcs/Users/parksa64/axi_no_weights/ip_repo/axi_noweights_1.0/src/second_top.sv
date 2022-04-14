
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
		input wire  s00_axi_rready
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
		.W0_WEN_OUT(w0_wen),
		.W1_WEN_OUT(w1_wen),
		.W2_WEN_OUT(w2_wen),
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
    wire w0_wen;
    wire w1_wen;
    wire w2_wen;
    wire w3_wen;
    wire start_cal_in;

    // ports of the NN module
    wire calc_done;
    wire [C_S00_AXI_DATA_WIDTH-1:0] calc_in;
    wire [C_S00_AXI_DATA_WIDTH-1:0] image_out [0:28][0:28];
    
    
    
    assign clk = s00_axi_aclk;
    assign resetn = s00_axi_aresetn;
    reg [C_S00_AXI_DATA_WIDTH-1:0] image [0:28][0:28];
    reg done_out;
    reg ready_out;
    reg [C_S00_AXI_DATA_WIDTH-1:0] final_out;
    

    //assign image_out = image;
    
    //simple finite state machine parameters
    reg [2:0] state;
    reg [2:0] next_state;
    parameter ready_s = 3'b000, img_write_s = 3'b001, calc_s = 3'b010;
    
    
    topLevel top(.clk(clk), .resetn(resetn), .startFlag(start_cal_in), .picTest(image) ,.handOff(calc_done), .calc_out(calc_in));
    
    integer i, j;
	
	
	always @(posedge clk) begin
        if (state == ready_s)
        begin
            ready_out <= 1'b1;
            done_out <= 1'b0;
            final_out <= 32'b0;
        end
        
        if (state == img_write_s)
        begin
            image[row_in][col_in] <= data_in;
            ready_out <= 1'b0;
            done_out <= 1'b1;
            final_out <= 32'b0;
        end
        
        if (state == calc_s)
        begin
            ready_out <= 1'b0;
            done_out <= calc_done;
            final_out <= calc_in;
        end
	end
	
	always @ (posedge clk) begin
		
		if (resetn == 1'b0) begin
		    state = ready_s;
			next_state = ready_s;
		end
		else if (state == ready_s && image_wen == 1'b1)
				next_state = img_write_s;
		else if (state == ready_s && start_cal_in == 1'b1)
				next_state = calc_s;
	    else if (state == img_write_s && image_wen == 1'b0)
				next_state = ready_s;
		else if (state == calc_s && start_cal_in == 1'b0) 
				next_state = ready_s;
		else next_state = state;
		state = next_state;
	end
	
	// User logic ends
	endmodule
	
    module topLevel(
        input clk,
        input resetn,
        input startFlag,
        input [31:0] picTest [0:28][0:28],
        output reg handOff,
        output reg [31:0] calc_out
    );
        always @ (posedge clk) begin
            if (startFlag == 1'b1) begin
                calc_out <= picTest[0][0] + picTest[1][1];
                handOff <= 1'b1;
            end
            else begin
                handOff <= 1'b0;
            end
        end
    
	endmodule
