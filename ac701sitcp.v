module
	ac701sitcp (
		input	wire			SYS_CLK_P,	//in
		input	wire			SYS_CLK_N,	//in
//connect EEPROM
		inout	wire			SDA_IO,	//inout
		output	wire			SCL_OUT,	//out
//Reset	IIC SWITCH
		input	wire			SW_N,		//input
//TX
		output	wire			PHY_TX_CLK,	//out	: Tx clock
		output	wire	[ 3:0]	PHY_TXD,	//out	: Tx signal line
		output	wire			PHY_TX_CTRL,//out
//RX
		input	wire			PHY_RX_CLK,	//in
		input	wire	[ 3:0]	PHY_RXD,	//in
		input	wire			PHY_RX_CTRL,//in
		output	wire			PHY_RSTn,  	//out	: SITCP reset
//DIPswitch
		input	wire	[ 3:0]	DIP
	);

//------------------------------------------------------------------------------
//     Clock_Genelation 200MHz -> 125MHz
//------------------------------------------------------------------------------
	wire			CLK_100M;
	wire			CLK_200M;
	reg				SYS_RSTn;
	wire			RST_EEPROM;
	reg		[15:0]	CNT0; 
	wire			PLL_CLKFB;
	wire			LOCKED;
	wire			CLK_125M_PLL_DELAY;
	
	//IIC
	reg				SYS_RSTn;
	wire			SCL_OUT;
	wire            SDA_IO;		
	//wire			SW_N;//reset switch
//Generate_200M//
	wire	IB_200M;
	IBUFDS	clk_buf	(.O(IB_200M),.I(SYS_CLK_P),.IB(SYS_CLK_N));

	

//PLL Primitive 200MHz -> 125MHz//

	wire	CLK_125M_PLL;
	wire	CLK_100M_PLL;
	wire	CLK_200M_PLL;

	
	

//------------------------------------------------------------------------------
//     Network Processor
//------------------------------------------------------------------------------
//Tx
	wire	[7:0]	GMII_TXD;			// out: Tx data[7:0]
	wire			GMII_TX_EN;				// out: Tx enable
	wire			GMII_TX_ER;				// out: TX error

//Rx
	wire	[7:0]	GMII_RXD;			// in : Rx data[7:0]
	wire			GMII_RX_DV;				// in : Rx data valid
	wire			GMII_RX_ER;				// in : Rx error
	wire			GMII_RX_CTRL;			// in
	wire			SiTCP_RST;				// out: Reset for SiTCP and related circuits
	wire			TCP_CLOSE_REQ;			// out: Connection close request
	wire	[15:0] 	STATUS_VECTOR;	// out: Core status.[15:0]	
	wire 	[7:0]	TCP_RX_DATA;
	wire		 	TCP_RX_WR;
	wire		 	TCP_TX_FULL;
	wire			TCP_OPEN_ACK;
	wire	[15:0]	FIFO_DATA_COUNT;
	wire 	[31:0]	RBCP_ADDR;
	wire 	[7:0]	RBCP_WD;
	wire	[47:0]	MAC;


	
	wire			EEPROM_CS;
	wire			EEPROM_SK;
	wire			EEPROM_DI;
	wire			EEPROM_DO;

//------------------------------------------------------------------------------
//     	RBCP
//------------------------------------------------------------------------------
	
	wire			RBCP_ACK;
	wire	[ 7:0]	RBCP_RD;


//------------------------------------------------------------------------------
//		RGMII
//------------------------------------------------------------------------------
	wire			GMII_TX_CLK;
	wire			GMII_TX_DCK;
	reg		[ 7:0]	CNT_RXC;
	reg				RST_RX_CNT;
	reg		[ 1:0]	RXC_SPEED;
	reg				GMII_1000M;
	reg		[ 4:0]	DIV_10M;
	reg		[ 2:0]	DIV_100M;
	reg				GMII_CLK_EN;
	reg		[ 6:0]	CNT_1G;
	reg		[ 3:0]	CNT_100M;


	BUFGCE	CLK125_BG		(.O(GMII_TX_CLK), 		.I(CLK_125M_PLL),		.CE(GMII_CLK_EN));
	BUFGCE	CLK125_BG_DELAY	(.O(GMII_TX_DCK),		.I(CLK_125M_PLL_DELAY),	.CE(GMII_CLK_EN));
	BUFG	CLK125_BG_REF	(.O(CLK_125M),			.I(CLK_125M_PLL_DELAY));

	initial	CNT_RXC[7:0]	= 8'h00;
	initial	RST_RX_CNT		= 1;
	initial	RXC_SPEED[1:0]	= 2'b00;
	initial	GMII_1000M		= 0;
	initial	DIV_10M[4:0]	= 5'b0_0000;
	initial	DIV_100M[2:0]	= 3'b000;
	initial	GMII_CLK_EN		= 0;
	
	always@(posedge CLK_125M)begin
		CNT_RXC[7:0]	<= CNT_RXC[7]?	8'd0:	(CNT_RXC[7:0] + 8'd1);
		RST_RX_CNT		<= CNT_RXC[7];
		RXC_SPEED[1:0]	<= CNT_RXC[7]?		{CNT_1G[6],CNT_100M[3]}:		RXC_SPEED[1:0];
		GMII_1000M		<= RXC_SPEED[1];
		DIV_10M[4:0]	<= DIV_10M[4]?	{RXC_SPEED[0],4'd8}:		(DIV_10M[4:0] - 5'd1);
		if (DIV_10M[4])	DIV_100M[2:0]	<= DIV_100M[2]?	{RXC_SPEED[1],2'd3}:		(DIV_100M[2:0] - 3'd1);
		GMII_CLK_EN		<= DIV_10M[4] & DIV_100M[2];
	end

	always@(posedge GMII_RX_CLK or posedge RST_RX_CNT)begin
		if (RST_RX_CNT) begin
			CNT_1G[6:0]		<= 7'b000_0000;
			CNT_100M[3:0]	<= 4'b000;
		end else begin
			CNT_1G[6:0]		<= CNT_1G[6:0] + {6'b000_000,~CNT_1G[6]};	// 64*8ns  = 512ns
			CNT_100M[3:0]	<= CNT_100M[3:0] + {3'b000,~CNT_100M[3]};	// 16*40ns = 640ns
		end
	end


	PLLE2_BASE #(
		.BANDWIDTH		("LOW"),
		.CLKFBOUT_MULT	(5),
		.CLKFBOUT_PHASE	(0.000),
		.CLKIN1_PERIOD	(5.000),
		.DIVCLK_DIVIDE	(1),
		.REF_JITTER1	(0.010),
		.CLKOUT0_DIVIDE	(8),
		.CLKOUT0_DUTY_CYCLE	(0.500),
		.CLKOUT0_PHASE	(0.000),
		.CLKOUT1_DIVIDE	(8),
		.CLKOUT1_DUTY_CYCLE	(0.500),
		.CLKOUT1_PHASE	(90.0),
		.CLKOUT2_DIVIDE	(10),
		.CLKOUT2_DUTY_CYCLE	(0.500),
		.CLKOUT2_PHASE	(0),
		.CLKOUT3_DIVIDE	(5),
		.CLKOUT3_DUTY_CYCLE	(0.500),
		.CLKOUT3_PHASE	(0)
	)
		PLLE2_BASE(
			.CLKFBOUT	(PLL_CLKFB),
			.CLKOUT0	(CLK_125M_PLL),
			.CLKOUT1	(CLK_125M_PLL_DELAY),
			.CLKOUT2	(CLK_100M_PLL),
			.CLKOUT3	(CLK_200M_PLL),
			.CLKOUT4	(),
			.CLKOUT5	(),
			.LOCKED		(LOCKED),
			.CLKFBIN	(PLL_CLKFB),
			.CLKIN1		(IB_200M),
			.PWRDWN		(1'b0),
			.RST		(1'b0)
		);

	BUFG	CLK100_BG		(.O(CLK_100M),			.I(CLK_100M_PLL));
	BUFG	CLK200_BG		(.O(CLK_200M),			.I(CLK_200M_PLL));

	//SYS_RSTn->off//
	always@(posedge CLK_200M or negedge LOCKED)begin
		if (LOCKED==1'b0) begin
			CNT0[15:0]	<= 16'd0;
			SYS_RSTn	<= 1'b0;
		end else begin
			CNT0[15:0] <= CNT0[15]? CNT0[15:0]:(CNT0[15:0]+16'd1);
			SYS_RSTn <= CNT0[15];
		end
	end


//------------------------------------------------------------------------------
//     AT93C46_IIC
//------------------------------------------------------------------------------	
	AT93C46_IIC #(
		.PCA9548_AD			(7'b1110_100),				// PCA9548 Dvice Address
		.PCA9548_SL			(8'b0001_1000),				// PCA9548 Select code (Ch3,Ch4 enable)
		.IIC_MEM_AD			(7'b1010_100),				// IIC Memory Dvice Address
		.FREQUENCY			(8'd200),					// CLK_IN Frequency  > 10MHz
		.DRIVE				(4),						// Output Buffer Strength
		.IOSTANDARD			("LVCMOS33"),				// I/O Standard
		.SLEW				("SLOW")					// Outputbufer Slew rate
	)
	AT93C46_IIC(
		.CLK_IN			(CLK_200M		),			// System Clock
		.RESET_IN		(~SYS_RSTn		),			// Reset
		.IIC_INIT_OUT	(RST_EEPROM		),			// IIC , AT93C46 Initialize (0=Initialize End)
		.EEPROM_CS_IN	(EEPROM_CS		),			// AT93C46 Chip select
		.EEPROM_SK_IN	(EEPROM_SK		),			// AT93C46 Serial data clock
		.EEPROM_DI_IN	(EEPROM_DI		),			// AT93C46 Serial write data (Master to Memory)
		.EEPROM_DO_OUT	(EEPROM_DO		),			// AT93C46 Serial read data(Slave to Master)
		.INIT_ERR_OUT	(				),			// PCA9548 Initialize Error
		.IIC_REQ_IN		(1'b0			),			// IIC Request
		.IIC_NUM_IN		(8'b0			),			// IIC Number of Access[7:0]	0x00:1Byte , 0xff:256Byte
		.IIC_DAD_IN		(7'b0			),			// IIC Device Address[6:0]
		.IIC_ADR_IN		(8'b0			),			// IIC Word Address[7:0]
		.IIC_RNW_IN		(1'b0			),			// IIC Read(1) / Write(0)
		.IIC_WDT_IN		(8'b0			),			// IIC Write Data[7:0]
		.IIC_RAK_OUT	(				),			// IIC Request Acknowledge
		.IIC_WDA_OUT	(				),			// IIC Wite Data Acknowledge(Next Data Request)
		.IIC_WAE_OUT	(				),			// IIC Wite Last Data Acknowledge(same as IIC_WDA timing)
		.IIC_BSY_OUT	(				),			// IIC Busy
		.IIC_RDT_OUT	(8'b0 			),			// IIC Read Data[7:0]
		.IIC_RVL_OUT	(				),			// IIC Read Data Valid
		.IIC_EOR_OUT	(				),			// IIC End of Read Data(same as IIC_RVL timing)
		.IIC_ERR_OUT	(				),			// IIC Error Detect
		// Device Interface
		.IIC_SCL_OUT	(SCL_OUT		),			// IIC Clock U52 ch0 U52.19	portN18
		.IIC_SDA_IO		(SDA_IO			)			// IIC Data  U52 ch3 U52.20 portK25
	);





	IDELAYCTRL (
		.RDY(), 
		.REFCLK(CLK_200M),
		.RST(1'd0)
	);

	RGMII2GMII	RGMII2GMII(
		.RGMII_RX_CLK	(PHY_RX_CLK			),
    	.RGMII_RXD		(PHY_RXD[3:0]		),
    	.RGMII_RXCTL	(PHY_RX_CTRL		),
    	.GMII_RX_CLK	(GMII_RX_CLK		),
    	.GMII_RXD		(GMII_RXD[7:0]		),
    	.GMII_RX_DV		(GMII_RX_DV			),
    	.GMII_RX_ER		(GMII_RX_ER			)
    );

	GMII2RGMII GMII2RGMII(
		.GMII_1000M		(GMII_1000M			),
		.GMII_TXD		(GMII_TXD[7:0]		),
    	.GMII_TX_CLK	(GMII_TX_CLK		),
    	.GMII_TX_DCK	(GMII_TX_DCK		),
    	.GMII_TX_EN		(GMII_TX_EN			),
    	.GMII_TX_ER		(GMII_TX_ER			),
    	.RGMII_TXD		(PHY_TXD[3:0]		),
    	.RGMII_TX_CTRL	(PHY_TX_CTRL		),
    	.RGMII_TX_CLK	(PHY_TX_CLK			)
    );
	
	    






//------------------------------------------------------------------------------
//     SiTCP
//------------------------------------------------------------------------------	
	WRAP_SiTCP_GMII_XC7A_32K	#(
		.TIM_PERIOD		(8'd200)			// 200MHz
	)
	SiTCP(
		.CLK			(CLK_200M   	 ),	// in	: System Clock >129MHz
		.RST			(RST_EEPROM		 ),	// in	: System reset
	// Configuration parameters
		.FORCE_DEFAULTn	(DIP[0]			 ),	// in	: Load default parameters
		.EXT_IP_ADDR	(32'd0			 ),	// in	: IP address[31:0]
		.EXT_TCP_PORT	(16'd0			 ),	// in	: TCP port #[15:0]
		.EXT_RBCP_PORT	(16'd0			 ),	// in	: RBCP port #[15:0]
		.PHY_ADDR		(5'd0			 ),	// in	: PHY-device MIF address[4:0]
	// EEPROM
		.EEPROM_CS		(EEPROM_CS		),	// out	: Chip select
		.EEPROM_SK		(EEPROM_SK		),	// out	: Serial data clock
		.EEPROM_DI		(EEPROM_DI		),	// out	: Serial write data
		.EEPROM_DO		(EEPROM_DO		),	// in	: Serial read data
	// user data, intialial values are stored in the EEPROM, 0xFFFF_FC3C-3F
		.USR_REG_X3C	(				),	// out	: Stored at 0xFFFF_FF3C
		.USR_REG_X3D	(				),	// out	: Stored at 0xFFFF_FF3D
		.USR_REG_X3E	(				),	// out	: Stored at 0xFFFF_FF3E
		.USR_REG_X3F	(				),	// out	: Stored at 0xFFFF_FF3F
	// MII interface 
		.GMII_RSTn		(PHY_RSTn		),	// out	: PHY reset Active low
		.GMII_1000M		(GMII_1000M		),	// in	: GMII mode (0:MII, 1:GMII)
		// TX
		.GMII_TX_CLK	(GMII_TX_CLK	),	// in	: Tx clock
		.GMII_TX_EN		(GMII_TX_EN		),	// out	: Tx enable
		.GMII_TXD		(GMII_TXD[7:0]	),	// out	: Tx data[7:0]
		.GMII_TX_ER		(GMII_TX_ER		),	// out	: TX error
		// RX
		.GMII_RX_CLK	(GMII_RX_CLK	),	// in	: Rx clock
		.GMII_RX_DV		(GMII_RX_DV		),	// in	: Rx data valid
		.GMII_RXD		(GMII_RXD[7:0]	),	// in	: Rx data[7:0]
		.GMII_RX_ER		(GMII_RX_ER		),	// in	: Rx error
		.GMII_CRS		(1'b0			),	// in	: Carrier sense
		.GMII_COL		(1'b0			),	// in	: Collision detected
		// Management IF
		.GMII_MDC		(				),	// out	: Clock for MDIO
		.GMII_MDIO_IN	(1'b1			),	// in	: Data
		.GMII_MDIO_OUT	(				),	// out	: Data
		.GMII_MDIO_OE	(				),	// out	: MDIO output enable
	// User I/F
		.SiTCP_RST		(SiTCP_RST		),	// out	: Reset for SiTCP and related circuits
		// TCP connection control
		.TCP_OPEN_REQ	(1'b0			),	// in	: Reserved input, shoud be 0
		.TCP_OPEN_ACK	(TCP_OPEN_ACK	),	// out	: Acknowledge for open (=Socket busy)
		.TCP_ERROR		(				),	// out	: TCP error, its active period is equal to MSL
		.TCP_CLOSE_REQ	(TCP_CLOSE_REQ	),	// out	: Connection close request
		.TCP_CLOSE_ACK	(TCP_CLOSE_REQ	),	// in		: Acknowledge for closing
		// FIFO I/F
		.TCP_RX_WC		(FIFO_DATA_COUNT[15:0]),	// in	: Rx FIFO write count[15:0] (Unused bits should be set 1)
		.TCP_RX_WR		(TCP_RX_WR		),	// out	: Write enable
		.TCP_RX_DATA	(TCP_RX_DATA	),	// out	: Write data[7:0]
		.TCP_TX_FULL	(TCP_TX_FULL	),	// out	: Almost full flag
		.TCP_TX_WR		(TCP_TX_WR		),	// in		: Write enable
		.TCP_TX_DATA	(TCP_TX_DATA	),	// in	: Write data[7:0]
		// RBCP
		.RBCP_ACT		(				),	// out	: RBCP active
		.RBCP_ADDR		(RBCP_ADDR[31:0]),	// out	: Address[31:0]
		.RBCP_WD		(RBCP_WD[7:0]	),	// out	: Data[7:0]
		.RBCP_WE		(RBCP_WE		),	// out	: Write enable
		.RBCP_RE		(RBCP_RE		),	// out	: Read enable
		.RBCP_ACK	  	(RBCP_ACK		),	// in	: Access acknowledge
		.RBCP_RD		(RBCP_RD[7:0]	)	// in	: Read data[7:0]
	);
//------------------------------------------------------------------------------
//     RBCP	TEST PLOGRAM
//------------------------------------------------------------------------------
	
	RBCP	RBCP(
		.CLK_200M	(CLK_200M),	//in
		.DIP		(DIP[3:1]),		//in
		.RBCP_WE	(RBCP_WE),	//in
		.RBCP_RE	(RBCP_RE),	//in
		.RBCP_WD	(RBCP_WD),	//in
		.RBCP_ADDR	(RBCP_ADDR),//in
		.RBCP_RD	(RBCP_RD),	//out
		.RBCP_ACK	(RBCP_ACK)	//out
	
	);
  
endmodule

