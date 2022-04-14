
`timescale 1 ns / 1 ps

	module axi_noweights_v1_0 #
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
		output wire [7:0] AN,
		output wire CA,
		output wire CB,
		output wire CC,
		output wire CD,
		output wire CE,
		output wire CF,
		output wire CG,
		
		output wire DP,
		
		//Debug with sys ILA

		
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


	// Add user logic here
    second_top top(.s00_axi_aclk(s00_axi_aclk),
		.s00_axi_aresetn(s00_axi_aresetn),
		.s00_axi_awaddr(s00_axi_awaddr),
		.s00_axi_awprot(s00_axi_awprot),
		.s00_axi_awvalid(s00_axi_awvalid),
		.s00_axi_awready(s00_axi_awready),
		.s00_axi_wdata(s00_axi_wdata),
		.s00_axi_wstrb(s00_axi_wstrb),
		.s00_axi_wvalid(s00_axi_wvalid),
		.s00_axi_wready(s00_axi_wready),
		.s00_axi_bresp(s00_axi_bresp),
		.s00_axi_bvalid(s00_axi_bvalid),
		.s00_axi_bready(s00_axi_bready),
		.s00_axi_araddr(s00_axi_araddr),
		.s00_axi_arprot(s00_axi_arprot),
		.s00_axi_arvalid(s00_axi_arvalid),
		.s00_axi_arready(s00_axi_arready),
		.s00_axi_rdata(s00_axi_rdata),
		.s00_axi_rresp(s00_axi_rresp),
		.s00_axi_rvalid(s00_axi_rvalid),
		.s00_axi_rready(s00_axi_rready),
		.AN(AN),
		.CA(CA),
		.CB(CB),
		.CC(CC),
		.CD(CD),
		.CE(CE),
		.CF(CF),
		.CG(CG),
		.DP(DP),

		 
		 .lin_out0(lin_out0),
		 .lin_out1(lin_out1),
		 .lin_out2(lin_out2),
		 .lin_out3(lin_out3),
		 .lin_out4(lin_out4),
		 .lin_out5(lin_out5),
		 .lin_out6(lin_out6),
		 .lin_out7(lin_out7),
		 .lin_out8(lin_out8),
		 .lin_out9(lin_out9)
		 , .copyIn_out(copyIn_out), .selectedWeight_out(selectedWeight_out), .f1Out_out(f1Out_out),
		 .curResult_out(curResult_out), .selectedBias_out(selectedBias_out), .f2Out_out(f2Out_out),
		 .Om_out(Om_out),  .Xm_out(Xm_out), .Ym_out(Ym_out), .toShift_out(toShift_out));
	// User logic ends

	endmodule
