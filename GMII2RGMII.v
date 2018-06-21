module
	GMII2RGMII(
		input	wire			GMII_1000M,
		input	wire	[7:0]	GMII_TXD,
		input	wire			GMII_TX_CLK,
		input	wire			GMII_TX_DCK,
		input	wire			GMII_TX_EN,
		input	wire			GMII_TX_ER,
		output	wire	[3:0]	RGMII_TXD,
		output	wire			RGMII_TX_CTRL,
		output	wire			RGMII_TX_CLK
	);

	reg 	[ 7:0]	PRE_TXD_P;
	reg		[ 3:0]	PRE_TXD_N;
	reg 	[ 1:0]	PRE_CTRL_P;
	reg				PRE_CTRL_N;


	always@(posedge(GMII_TX_CLK))	begin
		PRE_TXD_P[7:0]	<= GMII_1000M?	GMII_TXD[7:0]:		{GMII_TXD[3:0],GMII_TXD[3:0]};
	end

	always@(negedge(GMII_TX_CLK)) begin
		PRE_TXD_N[3:0]	<= PRE_TXD_P[7:4];
	end

	generate
		genvar I;
		for (I=0;I<4;I=I+1) begin: gen_ddr
			ODDR		#(
				.DDR_CLK_EDGE	("OPPOSITE_EDGE"),		// "OPPOSITE_EDGE" or "SAME_EDGE" 
				.INIT			(1'b0),					// Initial value of Q: 1'b0 or 1'b1
				.SRTYPE			("SYNC")				// Set/Reset type: "SYNC" or "ASYNC" 
			)
			ODDR_inst	(
				.Q				(RGMII_TXD[I]),			// 1-bit DDR output
				.C				(GMII_TX_CLK),			// 1-bit clock input
				.CE				(1'b1),					// 1-bit clock enable input
				.D1				(PRE_TXD_P[I]),			// 1-bit data input (positive edge)
				.D2				(PRE_TXD_N[I]),			// 1-bit data input (negative edge)
				.R				(1'b0),					// 1-bit reset
				.S				(1'd0)					// 1-bit set
			);
		end
	endgenerate

	always@(posedge(GMII_TX_CLK)) begin
		PRE_CTRL_P[0]	<= GMII_TX_EN;
		PRE_CTRL_P[1]	<= GMII_TX_EN^GMII_TX_ER;
	end
 
	always@(negedge(GMII_TX_CLK)) begin
		PRE_CTRL_N		<= PRE_CTRL_P[1];
	end


	ODDR		#(
		.DDR_CLK_EDGE	("OPPOSITE_EDGE"),		// "OPPOSITE_EDGE" or "SAME_EDGE" 
		.INIT			(1'b0),					// Initial value of Q: 1'b0 or 1'b1
		.SRTYPE			("SYNC")				// Set/Reset type: "SYNC" or "ASYNC" 
	)
	ODDR_inst	(
		.Q				(RGMII_TX_CTRL),		// 1-bit DDR output
		.C				(GMII_TX_CLK),			// 1-bit clock input
		.CE				(1'b1),					// 1-bit clock enable input
		.D1				(PRE_CTRL_P[0]),		// 1-bit data input (positive edge)
		.D2				(PRE_CTRL_N),			// 1-bit data input (negative edge)
		.R				(1'b0),					// 1-bit reset
		.S				(1'd0)					// 1-bit set
	);	
 
	ODDR		#(
		.DDR_CLK_EDGE	("OPPOSITE_EDGE"),		// "OPPOSITE_EDGE" or "SAME_EDGE" 
		.INIT			(1'b0),					// Initial value of Q: 1'b0 or 1'b1
		.SRTYPE			("SYNC")				// Set/Reset type: "SYNC" or "ASYNC" 
	)
	ODDR_clk	(
		.Q				(RGMII_TX_CLK),			// 1-bit DDR output
		.C				(GMII_TX_DCK),			// 1-bit clock input
		.CE				(1'b1),					// 1-bit clock enable input
		.D1				(1),					// 1-bit data input (positive edge)
		.D2				(0),					// 1-bit data input (negative edge)
		.R				(1'b0),					// 1-bit reset
		.S				(1'd0)					// 1-bit set
	);

endmodule