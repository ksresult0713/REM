`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    09:23:52 04/10/2019 
// Design Name: 
// Module Name:    rot_enc_test 
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
module rot_enc_test(
	 input CLK_6, CLK_60,
	 input RST,

	 input enc_A,
	 input enc_B,
	 input enc_Z,
	 input PLS,

	 input [15:0]dac_org,
	 input [15:0]dac_width_10V,

	 output reg [15:0]DA16_DATA_A,
	 output reg [15:0]pos_mul,
	 input [15:0]pos_data,
	 output reg [15:0]pos_range,

	 output reg [15:0]DA16_DATA_B,
	 output reg [31:0]rpm_div,
	 input [31:0]rpm_data,
	 input [15:0]rpm_range,
	 
	 output reg [15:0]dac_width_10V_mul,
	 output reg [15:0]rpm_range_mul,
	 
	 input SW1, SW2, SW5, SW6,
	 
	 input calib_org,
	 input calib_10V
    );

/********************************************************************************/
	/* A相、B相、Z相の変化を記録 */
/********************************************************************************/	
	reg [1:0]cnt_A;
	reg [1:0]cnt_B;
	reg [1:0]cnt_Z;
	reg [1:0]cnt_PLS;
	
	always @(posedge CLK_60) begin
		cnt_A <= {cnt_A[0], enc_A};
		cnt_B <= {cnt_B[0], enc_B};
		cnt_Z <= {cnt_Z[0], enc_Z};
		cnt_PLS <= {cnt_PLS[0], PLS};
	end

/********************************************************************************/
	/*位置のレンジ切り替え*/
/********************************************************************************/

	always @(posedge CLK_60 or posedge RST) begin
		if (RST) begin
			pos_range <= 4000;
		end else begin
			if ({SW6, SW5} == 2'b01) begin /*UTMⅡ(0.05Nm~10Nm)*/
				if (SW1) begin
					pos_range <= 2000; /*±90°*/
				end else begin
					pos_range <= 4000; /*±180°*/
				end
			end else if ({SW6, SW5} == 2'b10) begin /*UTMⅡ(20Nm, 50Nm)*/
				if (SW1) begin
					pos_range <= 1440; /*±90°*/
				end else begin
					pos_range <= 2880; /*±180°*/
				end
			end else if ({SW6, SW5} == 2'b11) begin /*UTMⅢ*/
				if (SW1) begin
					pos_range <= 3600; /*±90°*/
				end else begin
					pos_range <= 7200; /*±180°*/
				end
			end else begin /*初期状態*/
				if (SW1) begin
					pos_range <= 2000; /*±90°*/
				end else begin
					pos_range <= 4000; /*±180°*/
				end
			end
		end
	end
	
/********************************************************************************/
	/*位置のカウンター*/
/********************************************************************************/
	//pos_range : dac_width_10V = enc_cnt : DA16_DATA_A 
	
	reg [15:0]enc_cnt;
	
	always @(posedge CLK_60 or posedge RST) begin
		if (RST) begin
			enc_cnt <= 16'h8000; //32768(enc_cntの基準)
		end else begin
			if (Z_RST | PLS_RST) begin
				enc_cnt <= 16'h8000;
			end else begin
				if (SW1) begin /*range ±180°*/
					if (({cnt_A, cnt_B} == 4'b0111) | ({cnt_A, cnt_B} == 4'b1110) | 
					    ({cnt_A, cnt_B} == 4'b1000) | ({cnt_A, cnt_B} == 4'b0001)) begin /*負方向*/
						if (enc_cnt == 16'h8000 - pos_range) begin /*-90°を超えたらキープ*/
							enc_cnt <= 16'h8000 - pos_range;
						end else begin
							enc_cnt <= enc_cnt - 1;
						end
					end else if (({cnt_A, cnt_B} == 4'b0100) | ({cnt_A, cnt_B} == 4'b0010) | 
								 ({cnt_A, cnt_B} == 4'b1011) | ({cnt_A, cnt_B} == 4'b1101)) begin /*正方向*/
						if (enc_cnt == 16'h8000 + pos_range - 1) begin /*90°を超えたらキープ*/
							enc_cnt <= 16'h8000 + pos_range - 1;
						end else begin
							enc_cnt <= enc_cnt + 1;
						end
					end
				end else begin /*range ±90°*/
					if (({cnt_A, cnt_B} == 4'b0111) | ({cnt_A, cnt_B} == 4'b1110) | 
					    ({cnt_A, cnt_B} == 4'b1000) | ({cnt_A, cnt_B} == 4'b0001)) begin /*負方向*/
						if (enc_cnt == 16'h8000 - pos_range) begin /*-180°=>180°*/
							enc_cnt <= 16'h8000 + pos_range - 1;
						end else begin
							enc_cnt <= enc_cnt - 1;
						end
					end else if (({cnt_A, cnt_B} == 4'b0100) | ({cnt_A, cnt_B} == 4'b0010) | 
								 ({cnt_A, cnt_B} == 4'b1011) | ({cnt_A, cnt_B} == 4'b1101)) begin /*正方向*/
						if (enc_cnt == 16'h8000 + pos_range - 1) begin /*180°=>-180°*/
							enc_cnt <= 16'h8000 - pos_range;
						end else begin
							enc_cnt <= enc_cnt + 1;
						end
					end
				end
			end
		end
	end
	
/********************************************************************************/
	/*位置のカウントをDACの出力値に換算*/
/********************************************************************************/
	
	reg [5:0]pos_seq;
	reg pos_sign;
	/*position => DAC*/
	always @(posedge CLK_60 or posedge RST) begin
		if (RST) begin
			pos_seq <= 0;
			
			pos_mul <= 16'h0000;
			pos_sign <= 0;
			
			DA16_DATA_A <= 16'h8000;
		end else begin	
			if (calib_org) begin
				DA16_DATA_A <= dac_org;
			end else if (calib_10V) begin
				DA16_DATA_A <= dac_org + dac_width_10V;
			end else begin
				if (pos_seq == 0) begin /*enc_cntの正負と絶対値を確定する*/
					if (enc_cnt >= 16'h8000) begin
						pos_mul <= enc_cnt - 16'h8000;
						pos_sign <= 0;
					end else begin
						pos_mul <= 16'h8000 - enc_cnt;
						pos_sign <= 1;
					end					
					pos_seq <= 1;
				end else if (pos_seq <= 62) begin /*multiply_pos と division_posの処理待ち*/
					pos_seq <= pos_seq + 1;
				end else if (pos_seq == 63) begin /*換算された値をDACの出力値にする*/
					if (pos_sign) begin
						DA16_DATA_A <= dac_org - pos_data;
					end else begin
						DA16_DATA_A <= dac_org + pos_data;
					end
					pos_seq <= 0;
				end
			end
		end
	end
	
/********************************************************************************/
	/*Z相を使ったリセット*/
/********************************************************************************/

	reg Z_RST;

	always @(posedge CLK_60 or posedge RST) begin
		if (RST) begin
			Z_RST <= 0;
		end else begin
			if (SW2) begin
				if ({SW6, SW5} == 2'b01) begin //UTMⅡ(20Nm, 50Nm)
					case (cnt_Z)					
						2'b10   : Z_RST <= 1;
						default : Z_RST <= 0;
					endcase
				end else begin
					case (cnt_Z)					
						2'b01   : Z_RST <= 1;
						default : Z_RST <= 0;
					endcase
				end
			end
		end
	end
	
/********************************************************************************/
	/*外部入力パルスを使ったリセット*/
/********************************************************************************/

	reg PLS_RST;

	always @(posedge CLK_60 or posedge RST) begin
		if (RST) begin
			PLS_RST <= 0;
		end else begin
			case (cnt_PLS)					
				2'b01   : PLS_RST <= 1;
				default : PLS_RST <= 0;
			endcase
		end
	end
	
/********************************************************************************/
	
	reg [31:0]cnt_60MHz;
	reg rpm_rst;
	reg [1:0]rpm_rst_cnt;
	
	/* 60MHzのカウンタ */
	/*always @(posedge CLK_60 or posedge cnt_rst or posedge RST) begin
		if (RST | cnt_rst) begin
			cnt_60MHz <= 0;
			rpm_rst <= 0;
			rpm_rst_cnt <= 0;
		end else begin
			if (cnt_60MHz > 2500000) begin
				cnt_60MHz <= 32'hffffffff;
			end else begin
				cnt_60MHz <= cnt_60MHz + 1;
			end
		end
	end*/

	always @(posedge CLK_60 or posedge cnt_rst or posedge RST) begin
		if (RST | cnt_rst) begin
			cnt_60MHz <= 0;
			rpm_rst <= 0;
			rpm_rst_cnt <= 0;
		end else begin
			if (cnt_60MHz > 2500000) begin //10rpm
				if (rpm_rst_cnt == 0) begin
					rpm_rst <= 1;
					rpm_rst_cnt <= 1;
				end else if (rpm_rst_cnt == 1) begin
					rpm_rst <= 0;
					rpm_rst_cnt <= 2;
				end
				cnt_60MHz <= 32'hffffffff;
			end else begin
				cnt_60MHz <= cnt_60MHz + 1;
			end
		end
	end
	
/********************************************************************************/
	
	reg rot_minus;
	
	/* ロータリエンコーダの回転方向を判定 */
	always @(posedge CLK_60 or posedge RST) begin
		if (RST) begin
			rot_minus <= 0;
		end else begin
			case({cnt_A, cnt_B})
				4'b0111 : rot_minus <= 1;
				4'b1110 : rot_minus <= 1;
				4'b1000 : rot_minus <= 1;
				4'b0001 : rot_minus <= 1;
				
				4'b0100 : rot_minus <= 0;
				4'b0010 : rot_minus <= 0; 
				4'b1011 : rot_minus <= 0;
				4'b1101 : rot_minus <= 0;
				default : rot_minus <= rot_minus;
			endcase
		end
	end
	
/********************************************************************************/
	
	reg cnt_rst;
	reg [5:0]rpm_seq;
	reg rot_minus_buf;
	
	always @(posedge CLK_60 or posedge RST or posedge rpm_rst) begin
		if (RST | rpm_rst) begin
			rpm_div <= 32'hfffffff;
			rot_minus_buf <= 0;
			cnt_rst <= 0;
			
			dac_width_10V_mul <= 27962;
			rpm_range_mul <= 40;
			
			DA16_DATA_B <= 16'h8000;
			
			rpm_seq <= 0;
		end else begin
			if (rpm_seq == 0) begin
				case (cnt_A)					
					2'b01   : begin
									rpm_div <= cnt_60MHz;
									cnt_rst <= 1;
									rot_minus_buf <= rot_minus;
									
									dac_width_10V_mul <= dac_width_10V;
									rpm_range_mul <= rpm_range;
									
									rpm_seq <= 1;
								 end
					default : begin
									rpm_div <= rpm_div;
									cnt_rst <= 0;
									rot_minus_buf <= rot_minus_buf;
								 end
				endcase
			end else if (rpm_seq == 1) begin
				cnt_rst <= 0;
				rpm_seq <= 2;
			end else if (rpm_seq <= 62) begin
				rpm_seq <= rpm_seq + 1;
			end else if (rpm_seq == 63) begin
				if (rpm_data > dac_width_10V) begin
					if (rot_minus_buf) begin
						DA16_DATA_B <= dac_org - dac_width_10V; //-10V
					end else begin
						DA16_DATA_B <= dac_org + dac_width_10V; //+10V
					end
				end else begin
					if (rot_minus_buf) begin
						DA16_DATA_B <= dac_org - rpm_data[15:0];
					end else begin
						DA16_DATA_B <= dac_org + rpm_data[15:0];
					end
				end
				rpm_seq <= 0;
			end
		end
	end	

	/*always @(posedge CLK_60 or posedge RST) begin
		if (RST) begin
			rpm_div <= 32'hfffffff;
			rot_minus_buf <= 0;
			cnt_rst <= 0;
			
			dac_width_10V_mul <= 27962;
			rpm_range_mul <= 40;
			
			DA16_DATA_B <= 16'h8000;
			
			rpm_seq <= 0;
		end else begin
			if (rpm_seq == 0) begin
				case (cnt_A)					
					2'b01   : begin
									rpm_div <= cnt_60MHz;
									cnt_rst <= 1;
									rot_minus_buf <= rot_minus;
									
									dac_width_10V_mul <= dac_width_10V;
									rpm_range_mul <= rpm_range;
									
									rpm_seq <= 1;
								 end
					default : begin
									rpm_div <= rpm_div;
									cnt_rst <= 0;
									rot_minus_buf <= rot_minus_buf;
								 end
				endcase
			end else if (rpm_seq == 1) begin
				cnt_rst <= 0;
				rpm_seq <= 2;
			end else if (rpm_seq <= 62) begin
				rpm_seq <= rpm_seq + 1;
			end else if (rpm_seq == 63) begin
				if (rpm_data > dac_width_10V) begin
					if (rot_minus_buf) begin
						DA16_DATA_B <= dac_org - dac_width_10V; //-10V
					end else begin
						DA16_DATA_B <= dac_org + dac_width_10V; //+10V
					end
				end else begin
					if (rot_minus_buf) begin
						DA16_DATA_B <= dac_org - rpm_data[15:0];
					end else begin
						DA16_DATA_B <= dac_org + rpm_data[15:0];
					end
				end
				rpm_seq <= 0;
			end
		end
	end*/
	
	reg cnt_1ms;
	
	always @(posedge CLK_60 or posedge RST) begin
		if (RST) begin
			cnt_1ms <= 0;
		end else begin
		end
	end

endmodule
