`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    11:11:32 03/29/2019 
// Design Name: 
// Module Name:    SW_state 
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
module SW_state(
	input CLK_60, RST,
	
	input SW1, input SW2, input SW3, input SW4,
	input SW5, input SW6, input SW7, input SW8,
	
	input RESET_SW,
	
	output reg [15:0]dac_org,
	output reg [15:0]dac_width_10V,
	output reg [15:0]rpm_range,
	
	output reg calib_org,
	output reg calib_10V
    );
	 
	reg [15:0]cnt;
	reg [16:0]test_10V;
	
	always @(posedge CLK_60 or posedge RST) begin
		if (RST) begin
			dac_org <= 16'h8000;
			dac_width_10V <= 27692;
			rpm_range <= 400;
			
			calib_org <= 0;
			calib_10V <= 0;
			
			cnt <= 0;
		end else begin
			if (cnt == 60000) begin //1000Hz
				cnt <= 0;
			end else begin
				cnt <= cnt + 1;
			end
			
			/*キャリブレーション*/
			if (SW7 & ~SW8) begin
				calib_org <= 1;
				calib_10V <= 0;
				
				if (RESET_SW) begin
					if (cnt == 60000) begin
						if (dac_org == 37768) begin //32768 + 5000
							dac_org <= 27768; //32768 - 5000
						end else begin
							dac_org <= dac_org + 1;
						end
					end
				end
			end else if (SW7 & SW8) begin
				calib_org <= 0;
				calib_10V <= 1;
			
				if (RESET_SW) begin					
					test_10V <= dac_org + dac_width_10V;
					if (cnt == 60000) begin
						if ((test_10V == 16'hffff) | (dac_width_10V == 32692)) begin //27692 + 5000
							dac_width_10V <= 22692; //27692 - 5000
						end else begin
							dac_width_10V <= dac_width_10V + 1;
						end
					end
				end
			end else begin
				calib_org <= 0;
				calib_10V <= 0;
			end
			
			/*2000パルス or 1440パルス*/
			if ({SW6, SW5} == 2'b00) begin				
				if ({SW4, SW3} == 2'b00) begin 
					rpm_range <= 400; //(1/2000)*(1/4500)*6M*60
				end else if ({SW4, SW3} == 2'b01) begin
					rpm_range <= 900; //(1/2000)*(1/2000)*6M*60
				end else if ({SW4, SW3} == 2'b10) begin
					rpm_range <= 1800; //(1/2000)*(1/1000)*6M*60
				end else if ({SW4, SW3} == 2'b11) begin
					rpm_range <= 3600; //(1/2000)*(1/500)*6M*60
				end
			end else if ({SW6, SW5} == 2'b01) begin				
				if ({SW4, SW3} == 2'b00) begin 
					rpm_range <= 1250; //(1/1440)*(1/2000)*6M*60
				end else if ({SW4, SW3} == 2'b01) begin
					rpm_range <= 2500; //(1/1440)*(1/1000)*6M*60
				end else if ({SW4, SW3} == 2'b10) begin
					rpm_range <= 5000; //(1/1440)*(1/500)*6M*60
				end else if ({SW4, SW3} == 2'b11) begin
					rpm_range <= 10000; //(1/1440)*(1/250)*6M*60
				end
			end
		end
	end

endmodule
