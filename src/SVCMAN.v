`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    15:43:47 08/18/2014 
// Design Name: 
// Module Name:    main 
// Project Name: 
// Target Devices: 
// Tool versions: 
// Description: 
//
// Dependencies: 
//
// Revision: 
// Revision 0.01 - File Created
// Additional Comments: 
//
//////////////////////////////////////////////////////////////////////////////////
module main(
    input CLKIN, input RESET_B, input RESET2_B, input RESET_SW,
	 
    input SW1_B, input SW2_B, input SW3_B, input SW4_B,
	 input SW5_B, input SW6_B, input SW7_B, input SW8_B,

    output DA16_SCLK, output DA16_SYNC_B, output DA16_SDIN, output DA16_LDAC_B,

    output LED2_B, output LED3_B, output LED4_B, output LED5_B,
	 
	 input enc_A_B, input enc_B_B, input enc_Z_B
    );
	 
	 wire enc_A;
	 assign enc_A = ~enc_A_B;
	 wire enc_B;
	 assign enc_B = ~enc_B_B;
	 wire enc_Z;
	 assign enc_Z = ~enc_Z_B;
	 
	 wire RESET;
	 assign RESET = ~RESET_B;
	 wire PLS;
	 assign PLS = ~RESET2_B;
	 wire RST;
	 assign RST = (SW7)?(RST_BOOT | RESET):(RST_BOOT | RESET | RESET_SW);
	 
	 wire LED2;
	 assign LED2_B = ~LED2;
	 wire LED3;
	 assign LED3_B = ~LED3;
	 wire LED4;
	 assign LED4_B = ~LED4;
	 wire LED5;
	 assign LED5_B = ~LED5;
	 
	 assign LED2 = 1;
	 assign LED3 = enc_A;
	 assign LED4 = enc_B;
	 assign LED5 = ({SW6, SW5} == 2'b01)?~enc_Z:enc_Z;

/************************************************************************/
    wire CLK_6;
    wire CLK_60;

  clk2 instance_name
   (// Clock in ports
    .CLK_IN1(CLKIN),      // IN 25MHz
    // Clock out ports
    .CLK_6_00(CLK_6),     // OUT
    .CLK_60_00(CLK_60),     // OUT
    // Status and control signals
    .RESET(1'b0),// IN
    .LOCKED());      // OUT
	 
	 reg [3:0]rst_cnt;
	 reg RST_BOOT;
	 always @(posedge CLK_60) begin
		if (rst_cnt == 0) begin
			RST_BOOT <= 0;
			rst_cnt <= 1;
		end else if (rst_cnt == 1) begin
			RST_BOOT <= 1;
			rst_cnt <= 2;
		end else if (rst_cnt <= 10) begin
			rst_cnt <= rst_cnt + 1;
		end else if (rst_cnt == 11) begin
			RST_BOOT <= 0;
			rst_cnt <= 12;
		end
	 end
	 
/************************************************************************/
    /* ƒXƒCƒbƒ`ˆ— */
/************************************************************************/
	wire SW1;
	assign SW1 = ~SW1_B;
	wire SW2;
	assign SW2 = ~SW2_B;
	wire SW3;
	assign SW3 = ~SW3_B;
	wire SW4;
	assign SW4 = ~SW4_B;
	wire SW5;
	assign SW5 = ~SW5_B;
	wire SW6;
	assign SW6 = ~SW6_B;
	wire SW7;
	assign SW7 = ~SW7_B;
	wire SW8;
	assign SW8 = ~SW8_B;
	
	wire [15:0]dac_org;
	wire [15:0]dac_width_10V;
	
	wire [15:0]rpm_range;
	
	wire calib_org;
	wire calib_10V;
	
	SW_state SW_state(
		.CLK_60(CLK_60), .RST(RST),
		
		.SW1(SW1), .SW2(SW2), .SW3(SW3), .SW4(SW4),
		.SW5(SW5), .SW6(SW6), .SW7(SW7), .SW8(SW8),
		
		.RESET_SW(RESET_SW),
		
		.dac_org(dac_org),
		.dac_width_10V(dac_width_10V),
		.rpm_range(rpm_range),
		
		.calib_org(calib_org), .calib_10V(calib_10V)
	);

/************************************************************************/
    /* DACˆ— */
/************************************************************************/
	 wire [15:0]DA16_DATA_A;													 	
	 wire [15:0]DA16_DATA_B;
	
    SVC_DA16 SVC_DA16(
        .CLK_60(CLK_60), .RST(RST),

        .DA16_SCLK(DA16_SCLK), .DA16_SYNC_B(DA16_SYNC_B),
		  .DA16_SDIN(DA16_SDIN), .DA16_LDAC_B(DA16_LDAC_B),
		  
		  .DA16_DATA_A(DA16_DATA_A), .DA16_DATA_B(DA16_DATA_B)
    );

/************************************************************************/
    /* ?[ƒ^ƒŠ[ƒGƒ“ƒR[ƒ_ˆ— */
/************************************************************************/
	wire [15:0]pos_range;
	wire [15:0]pos_mul;
	wire [31:0]pos_data;
	
	wire [31:0]rpm_div;
	wire [31:0]rpm_data;
	
	wire [15:0]dac_width_10V_mul;
	wire [15:0]rpm_range_mul;
	
	rot_enc_test rot_enc_test(
		.CLK_6(CLK_6), .CLK_60(CLK_60),
		.RST(RST),
		
		.enc_A(enc_A), .enc_B(enc_B), .enc_Z(enc_Z), .PLS(PLS),

		.dac_org(dac_org),
		.dac_width_10V(dac_width_10V),

		.DA16_DATA_A(DA16_DATA_A),
		.pos_mul(pos_mul),
		.pos_data(pos_data[15:0]),
		.pos_range(pos_range),

		.DA16_DATA_B(DA16_DATA_B),
		.rpm_div(rpm_div),
		.rpm_data(rpm_data),
		.rpm_range(rpm_range),
		
		.dac_width_10V_mul(dac_width_10V_mul),
		.rpm_range_mul(rpm_range_mul),
		
		.SW1(SW1), .SW2(SW2), .SW5(SW5), .SW6(SW6),
		
		.calib_org(calib_org), .calib_10V(calib_10V)
	);

/************************************************************************/
    /* Š|‚¯ŽZ */
/************************************************************************/ 
	 wire [31:0]pos_div;
	 multiply_pos multiply_pos(
		.clk(CLK_60),
		.a(pos_mul),
		.b(dac_width_10V),
		.p(pos_div)
	 );

/************************************************************************/
    /* Š„‚èŽZ */
/************************************************************************/
	 division_pos division_pos(
		.clk(CLK_60),
		.dividend(pos_div),
		.divisor(pos_range),
		.quotient(pos_data),
		.fractional(),
		.rfd()
	 );
	 
/************************************************************************/
    /* Š|‚¯ŽZ */
/************************************************************************/ 
	 wire [31:0]rpm_mul;
	 multiply_rpm multiply_rpm(
		.clk(CLK_60),
		.a(dac_width_10V_mul),
		.b(rpm_range_mul),
		.p(rpm_mul)
	 );
	 
/************************************************************************/
    /* Š„‚èŽZ */
/************************************************************************/ 
	 division division(
		.clk(CLK_60),
		.dividend(rpm_mul),
		.divisor(rpm_div),
		.quotient(rpm_data),
		.fractional(),
		.rfd()
	 );
	
endmodule
