`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    17:00:40 07/24/2015 
// Design Name: 
// Module Name:    SVC_AD16 
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
module SVC_AD16(
    input CLK,
    input RES,

    output AD16_CS_B, input AD16_DOUT, output AD16_DIN, output AD16_SCLK, output AD16_CLK,

    output reg [31:0]AD16_DATA_A, output reg [31:0]AD16_DATA_B, output reg [31:0]AD16_DATA_SUB,
    input ENB, input HOLD,

    output TP0, output TP1, output TP2, output TP3
    );

    assign AD16_CLK = 1'bz;

    assign AD16_CS_B = ~CS;

    reg CS;

    reg  ADC_REQ;
    wire ADC_ACK;
    reg  [39:0] ADC_TXDATA;
    wire [39:0] ADC_RXDATA;
    reg  [ 2:0] ADC_LEN;
    reg  [ 4:0] ADC_RDY_CHKBIT;

    reg [7:0] adc_seq;

    reg  [31:0] A_reg;
    reg  [31:0] B_reg;

    reg       CmdReq;
    reg [3:0] cmd_seq;
    reg       ADC_CSA;
    reg       RDY_B;

    always @(posedge CLK or posedge RES) begin /* 60MHz */
        if (RES) begin
            AD16_DATA_A <= 0;
            AD16_DATA_B <= 0;
            RDY_B <= 1;
        end
        else begin
            if (~HOLD) begin
                AD16_DATA_A <= A_reg;
                AD16_DATA_B <= B_reg;
            end
            RDY_B <= AD16_DOUT;
        end
    end



    always @(posedge CLK or posedge RES) begin /* 60MHz */
        if (RES) begin
            ADC_TXDATA <= 0;
            ADC_LEN <= 1;
            ADC_RDY_CHKBIT <= 0;
            A_reg    <= 0;
            B_reg    <= 0;
            CmdReq <= 0;
            ADC_CSA <= 0;
            AD16_DATA_SUB <= 0;
            adc_seq <= 0;
        end
        else begin

            if (adc_seq == 0) begin
                adc_seq <= 1;
            /**********************************/
            end else if (adc_seq == 1) begin
                CmdReq <= 1;
                ADC_TXDATA[39:32] <= {2'b01, 6'b000111}; /* IDレジスタリード (Command) */
                ADC_LEN <= 3;
                ADC_RDY_CHKBIT <= 5'b00000;
                ADC_CSA <= 0;
                adc_seq <= 2;
            end else if (adc_seq == 2) begin
                if (cmd_seq == 4'hf) begin
                    CmdReq <= 0;
                    AD16_DATA_SUB[31:16] <= ADC_RXDATA[15:0];
                    adc_seq <= 3;
                end
            end else if (adc_seq == 3) begin
                if (ENB) adc_seq <= 4;
            /**********************************/
            end else if (adc_seq == 4) begin
                CmdReq <= 1;
                ADC_TXDATA[39:32] <= {2'b00, 6'h10}; /* チャンネル・マップ・レジスタ0 ライト (Command) */
                ADC_TXDATA[31:16] <= {1'b1, 1'b0, 2'b00, 2'b00, 5'b00000, 5'b10110}; 
                                                         /* Ch0 イネーブル         */
                                                         /*     セットアップ０使用 */
                                                         /*     AIN0 － REF- 間    */
                ADC_LEN <= 3;
                ADC_RDY_CHKBIT <= 5'b00000;
                ADC_CSA <= 0;
                adc_seq <= 5;
            end else if (adc_seq == 5) begin
                if (cmd_seq == 4'hf) begin
                    CmdReq <= 0;
                    adc_seq <= 6;
                end
            /**********************************/
            end else if (adc_seq == 6) begin
                CmdReq <= 1;
                ADC_TXDATA[39:32] <= {2'b00, 6'h11}; /* チャンネル・マップ・レジスタ1 ライト (Command) */
                ADC_TXDATA[31:16] <= {1'b1, 1'b0, 2'b00, 2'b00, 5'b00001, 5'b10110}; 
                                                         /* Ch1 イネーブル         */
                                                         /*     セットアップ０使用 */
                                                         /*     AIN1 － REF- 間    */
                ADC_LEN <= 3;
                ADC_RDY_CHKBIT <= 5'b00000;
                ADC_CSA <= 0;
                adc_seq <= 7;
            end else if (adc_seq == 7) begin
                if (cmd_seq == 4'hf) begin
                    CmdReq <= 0;
                    adc_seq <= 8;
                end
            /**********************************/
            end else if (adc_seq == 8) begin
                CmdReq <= 1;
                ADC_TXDATA[39:32] <= {2'b00, 6'h20}; /* セットアップ・コンフィギュレーション・レジスタ0 ライト (Command) */
                ADC_TXDATA[31:16] <= {3'b000, 1'b0, 6'b000000, 2'b10, 4'b0000}; 
                                                         /* ユニポーラ         */
                                                         /* 内蔵2.5 Vリファレンスイネーブル */
                ADC_LEN <= 3;
                ADC_RDY_CHKBIT <= 5'b00000;
                ADC_CSA <= 0;
                adc_seq <= 9;
            end else if (adc_seq == 9) begin
                if (cmd_seq == 4'hf) begin
                    CmdReq <= 0;
                    adc_seq <= 10;
                end
            /**********************************/
            end else if (adc_seq == 10) begin
                CmdReq <= 1;
                ADC_TXDATA[39:32] <= {2'b00, 6'h28}; /* フィルタ・コンフィギュレーション・レジスタ0 ライト (Command) */
                ADC_TXDATA[31:16] <= {11'b00000000000, 5'b00101}; 
                                                         /* 25,000sps         */
                ADC_LEN <= 3;
                ADC_RDY_CHKBIT <= 5'b00000;
                ADC_CSA <= 0;
                adc_seq <= 11;
            end else if (adc_seq == 11) begin
                if (cmd_seq == 4'hf) begin
                    CmdReq <= 0;
                    adc_seq <= 12;
                end
            /**********************************/
            end else if (adc_seq == 12) begin
                CmdReq <= 1;
                ADC_TXDATA[39:32] <= {2'b00, 6'h01}; /* ADCモード・レジスタ ライト (Command) */
                ADC_TXDATA[31:16] <= {1'b1, 1'b0, 1'b0, 2'b00, 3'b001, 1'b0, 3'b000, 2'b00, 2'b00}; 
                                                         /* 内蔵リファレンス電圧イネーブル         */
                                                         /* 4 μs遅延 */
                                                         /* 連続変換モード */
                                                         /* 内蔵発振器イネーブル */
                ADC_LEN <= 3;
                ADC_RDY_CHKBIT <= 5'b00000;
                ADC_CSA <= 0;
                adc_seq <= 13;
            end else if (adc_seq == 13) begin
                if (cmd_seq == 4'hf) begin
                    CmdReq <= 0;
                    adc_seq <= 14;
                end
            /**********************************/
            end else if (adc_seq == 14) begin
                CmdReq <= 1;
                ADC_TXDATA[39:32] <= {2'b00, 6'h02}; /* インターフェース・モード・レジスタ ライト (Command) */
                ADC_TXDATA[31:16] <= {3'b000, 1'b0, 1'b0, 2'b00, 1'b0, 1'b1, 1'b1, 1'b0, 1'b0, 2'b00, 1'b0, 1'b0}; 
                                                         /* 連続読出しイネーブル         */
                                                         /* ステータス情報イネーブル */
                                                         /* 24ビット・データ */
                ADC_LEN <= 3;
                ADC_RDY_CHKBIT <= 5'b00000;
                ADC_CSA <= 1; /****/
                adc_seq <= 15;
            end else if (adc_seq == 15) begin
                if (cmd_seq == 4'hf) begin
                    CmdReq <= 0;
                    adc_seq <= 16;
                end
            /**********************************/
            end else if (adc_seq == 16) begin
                adc_seq <= 8'h80;
            /**********************************/


            /**********************************/
            /**********************************/
            /**********************************/
            end else if (adc_seq[7]) begin
                if (adc_seq[6:0] == 7'h0) begin
                    ADC_TXDATA <= 0;
                    ADC_RDY_CHKBIT <= 5'b00000;
                    ADC_LEN <= 4;
                    ADC_CSA <= 1; /****/
                    adc_seq[6:0] <= 1;
                end else if (adc_seq[6:0] == 7'h1) begin
                    if (~RDY_B) begin
                        adc_seq[6:0] <= 2;
                    end
                end else if (adc_seq[6:0] == 7'h2) begin
                    CmdReq <= 1;
                    adc_seq[6:0] <= 3;
                end else if (adc_seq[6:0] == 7'h3) begin
                    if (cmd_seq == 4'hf) begin
                        CmdReq <= 0;
                        if (ADC_RXDATA[1:0] == 2'b00) begin
                            A_reg <= {ADC_RXDATA[7:0], ADC_RXDATA[31:8]};
                        end else begin
                            B_reg <= {ADC_RXDATA[7:0], ADC_RXDATA[31:8]};
                        end
                        adc_seq[6:0] <= 4;
                    end
                end else begin
                    if (ENB) begin
                        adc_seq[6:0] <= 1;
                    end else begin
                        adc_seq <= 0;
                    end
                end
            end


        end
    end





    always @(posedge CLK or posedge RES) begin /* 60MHz */
        if (RES) begin
            CS <= 0;
            ADC_REQ <= 0;
            cmd_seq <= 0;
        end
        else begin
            if (cmd_seq == 0) begin
                if (CmdReq) begin
                    cmd_seq <= 1;
                end
            end else if (cmd_seq == 1) begin
                if (ADC_ACK) begin
                    CS <= 1;
                    ADC_REQ <= 1;
                    cmd_seq <= 2;
                end
            end else if (cmd_seq == 2) begin
                if (~ADC_ACK) begin
                    ADC_REQ <= 0;
                    cmd_seq <= 3;
                end
            end else if (cmd_seq == 3) begin
                if (ADC_ACK) begin
                    CS <= ADC_CSA;
                    cmd_seq <= 4;
                end
            end else if (cmd_seq == 4) begin
                cmd_seq <= 5;
            end else if (cmd_seq == 5) begin
                cmd_seq <= 4'hf;
            end else begin
                if (~CmdReq) begin
                    cmd_seq <= 0;
                end
            end
        end
    end


    AD16_CMD AD16_CMD(
        .CLK(CLK), .RES(RES),
        .AD16_DOUT(AD16_DOUT), .AD16_DIN(AD16_DIN), .AD16_SCLK(AD16_SCLK),

        .REQ(ADC_REQ), .ACK(ADC_ACK),
        .TXDATA(ADC_TXDATA), .RXDATA(ADC_RXDATA),
        .LEN(ADC_LEN), .RDY_CHKBIT(ADC_RDY_CHKBIT)
    );



endmodule

/**********************************************/
module AD16_CMD(
    input CLK,
    input RES,

    input AD16_DOUT, output AD16_DIN, output AD16_SCLK,

    input REQ, output reg ACK,

    input [39:0]TXDATA, output reg [39:0]RXDATA,
    input [2:0]LEN, input [4:0]RDY_CHKBIT
    );

    reg RXD;

//    reg REQ_BAK;

    reg  ADC_REQ8;
    wire ADC_ACK8;
    wire [7:0]ADC_TXDATA8;
    wire [7:0]ADC_RXDATA8;
    wire RDY_CHK8;

    reg [39:0]TXDATA_tmp;
    reg [39:0]RXDATA_tmp;
    reg [2:0]LEN_tmp;
    reg [4:0]RDY_CHKBIT_tmp;

    reg [3:0]seq;

    reg [1:0]trcnt;

    assign ADC_TXDATA8 = TXDATA_tmp[39:32];
    assign RDY_CHK8 = RDY_CHKBIT_tmp[0];


    always @(posedge CLK or posedge RES) begin /* 60MHz */
        if (RES) begin
            RXD <= 0;
            ACK <= 1;
//            REQ_BAK <= 1;
            ADC_REQ8 <= 0;
            seq <= 0;
        end
        else begin
            RXD <= AD16_DOUT;
//            REQ_BAK <= REQ;
            if (seq == 0) begin
//                if ((~REQ_BAK) & (REQ)) begin
                if (REQ) begin
                    TXDATA_tmp[39:0] <= TXDATA[39:0];
                    LEN_tmp[2:0] <= LEN[2:0] - 1;
                    RDY_CHKBIT_tmp[4:0] <= RDY_CHKBIT[4:0];
                    seq <= 1;
                end
            end else if (seq == 1) begin
                if (ADC_ACK8) begin
                    ACK <= 0;
                    ADC_REQ8 <= 1;
                    seq <= 2;
                end else begin
                    ADC_REQ8 <= 0;
                    ACK <= 1;
                end
            end else if (seq == 2) begin
                if (~ADC_ACK8) begin
                    ADC_REQ8 <= 0;
                    seq <= 3;
                end
            end else if (seq == 3) begin
                if (ADC_ACK8) begin
//                    ADC_REQ8 <= 0;
                    RXDATA_tmp[39:0] <= {RXDATA_tmp[31:0], ADC_RXDATA8};
                    TXDATA_tmp[39:8] <= TXDATA_tmp[31:0];
                    RDY_CHKBIT_tmp[3:0] <= RDY_CHKBIT_tmp[4:1];
                    LEN_tmp[2:0] <= LEN_tmp[2:0] - 1;
                    if (LEN_tmp[2:0] == 0) begin
                        seq <= 4;
                    end else begin
                        seq <= 1;
                    end
                end
            end else if (seq == 4) begin
                RXDATA[39:0] <= RXDATA_tmp[39:0];
                ACK <= 1;
                seq <= 5;
            end else if (seq == 5) begin
//                REQ_BAK <= 1;
                seq <= 0;
            end
        end
    end



    AD16_8TR AD16_8TR(
        .CLK(CLK), .RES(RES),

        .rAD16_DOUT(RXD), .AD16_DIN(AD16_DIN), .AD16_SCLK(AD16_SCLK),

        .REQ(ADC_REQ8), .ACK(ADC_ACK8),
        .AD16_TXDATA(ADC_TXDATA8), .AD16_RXDATA(ADC_RXDATA8),
        .RDY_CHK(RDY_CHK8)
    );

endmodule

/**********************************************/
module AD16_8TR(
    input CLK,
    input RES,

    input rAD16_DOUT, output AD16_DIN, output AD16_SCLK,

    input REQ, output reg ACK,
    input [7:0]AD16_TXDATA, output reg [7:0]AD16_RXDATA,
    input RDY_CHK
    );


    reg SCLK;
    reg TXD;

//    reg REQ_BAK;

    wire RXD;

    reg [7:0]TXDATA;
    reg [7:0]RXDATA;

    reg [4:0]cnt;
    reg [3:0]cnt2;
    reg chk;
    reg [4:0]seq;


    assign AD16_SCLK = SCLK;
    assign AD16_DIN = TXD;

    assign RXD = rAD16_DOUT;


    always @(posedge CLK or posedge RES) begin /* 60MHz */
        if (RES) begin
            SCLK <= 1;
            TXD <= 0;
            AD16_RXDATA <= 0;
            RXDATA <= 0;
            ACK <= 1;
//            REQ_BAK <= 1;
            chk <= 0;
        end
        else begin
            cnt[4:0] <= cnt[4:0] + 1;

            if (cnt[3:0] == 4'b0000) begin /* 60/16/2 -> 1.875Mbps */
                if (seq == 0) begin
//                    REQ_BAK <= REQ;
//                    if ((~REQ_BAK) & (REQ)) begin
                    if (REQ) begin
                        TXDATA <= AD16_TXDATA;
                        ACK <= 0;
                        cnt2 <= 0;
                        chk <= RDY_CHK;
                        seq <= 1;
                    end else begin
                        ACK <= 1;
                    end
                end else if (seq == 1) begin
                    if ((~chk) | (~RXD)) begin
                        chk <= 0;
                        SCLK <= 0;
                        TXD <= TXDATA[7];
                        TXDATA[7:1] <= TXDATA[6:0];
                        cnt2 <= cnt2 + 1;
                        seq <= 2;
                    end else begin
                    end
                end else if (seq == 2) begin
                    SCLK <= 1;
                    RXDATA[7:0] <= {RXDATA[6:0], RXD};
                    if (~cnt2[3]) begin
                        seq <= 1;
                    end else begin
                        seq <= 3;
                    end
                end else if (seq == 3) begin
                    AD16_RXDATA[7:0] <= RXDATA[7:0];
                    ACK <= 1;
                    seq <= 4;
                end else begin
                    SCLK <= 1;
                    ACK <= 1;
//                    REQ_BAK <= 0;
                    seq <= 0;
                end
            end

        end
    end

endmodule



/**********************************************/
/**********************************************/
/**********************************************/
module SVC_DA16(
    input CLK_60, RST,

    output DA16_SCLK, output DA16_SYNC_B, 
	 output DA16_SDIN, output reg DA16_LDAC_B,
	 
    input [15:0]DA16_DATA_A, input [15:0]DA16_DATA_B
    );


    reg  [ 7:0] dac_seq;

    reg         DAC_REQ;

    reg  [ 3:0] DAC_CMD;
    reg  [ 3:0] DAC_ADR;
    reg  [15:0] DAC_DAT;

    reg  [13:0] cnt;

    wire [23:0] DAC_SD;
    wire        DAC_ACK;
	 
	 reg [27:0]seq_cnt;

    assign DAC_SD[23:0] = {DAC_CMD[3:0], DAC_ADR[3:0], DAC_DAT[15:0]};

    always @(posedge CLK_60 or posedge RST) begin /* 60MHz */
        if (RST) begin
            DAC_REQ <= 0;
            DAC_CMD <= 0;
            DAC_ADR <= 0;
            DAC_DAT <= 0;
            DA16_LDAC_B <= 1;
            cnt <= 0;
            dac_seq <= 0;
        end else begin
            if (dac_seq == 0) begin
                dac_seq <= 1;
                DAC_REQ <= 0;
                DA16_LDAC_B <= 1;
            end else if (dac_seq == 1) begin
                dac_seq <= 8'h80;

            end else if (dac_seq[7]) begin
                cnt <= cnt + 1;
                if (dac_seq[6:0] == 7'h0) begin
						cnt <= 0;
						DA16_LDAC_B <= 1;
						dac_seq[6:0] <= 7'h1;
                end else if (dac_seq[6:0] == 7'h1) begin
                    if (DAC_ACK) begin
                        DAC_CMD <= 4'b0001; /* Write to Input Register (dependent on LDAC) */
                        DAC_ADR <= 4'b0001; /* DAC A */
                        DAC_DAT <= DA16_DATA_A;
                        DAC_REQ <= 1;
                        dac_seq[6:0] <= 7'h2;
                    end else begin
                        DAC_REQ <= 0;
                    end
                end else if (dac_seq[6:0] == 7'h2) begin
                    if (~DAC_ACK) begin
                        DAC_REQ <= 0;
                        dac_seq[6:0] <= 7'h3;
                    end
                end else if (dac_seq[6:0] <= 7'h8) begin
                    if (DAC_ACK) begin
                        dac_seq[6:0] <= dac_seq[6:0] + 1;
                    end
                end else if (dac_seq[6:0] == 7'h9) begin
                    DAC_CMD <= 4'b0001; /* Write to Input Register (dependent on LDAC) */
                    DAC_ADR <= 4'b1000; /* DAC B */
                    DAC_DAT <= DA16_DATA_B;
                    DAC_REQ <= 1;
                    dac_seq[6:0] <= 7'ha;
                end else if (dac_seq[6:0] == 7'ha) begin
                    if (~DAC_ACK) begin
                        DAC_REQ <= 0;
                        dac_seq[6:0] <= 7'hb;
                    end
                end else if (dac_seq[6:0] <= 7'h10) begin
                    if (DAC_ACK) begin
                        dac_seq[6:0] <= dac_seq[6:0] + 1;
                    end
                end else if (dac_seq[6:0] <= 7'h16) begin
                    DA16_LDAC_B <= 0;
                    dac_seq[6:0] <= dac_seq[6:0] + 1;
                end else if (dac_seq[6:0] == 7'h17) begin
                    DA16_LDAC_B <= 1;
                    dac_seq[6:0] <= 7'h18;
                end else begin
                    if (cnt[13:0] == 398) begin /* 60MHz/(398+2) = 150kHz */
                        dac_seq[6:0] <= 7'h0;
                    end
                end
            end


        end
    end



    DA16_OUT DA16_OUT(
        .CLK_60(CLK_60), .RST(RST),
        .DA16_SCLK(DA16_SCLK), .DA16_SYNC_B(DA16_SYNC_B), .DA16_SDIN(DA16_SDIN),
        .REQ(DAC_REQ), .OUTDATA(DAC_SD),
        .ACK(DAC_ACK)
    );


endmodule

/**********************************************/
module DA16_OUT(
    input CLK_60, RST,

    output DA16_SCLK, output DA16_SYNC_B, output DA16_SDIN,

    input REQ, input [23:0]OUTDATA,
    output reg ACK
    );

    assign DA16_SCLK = SCLK;
    assign DA16_SYNC_B = ~CS;
    assign DA16_SDIN = TXD;

    reg SCLK;
    reg CS;
    reg TXD;
    reg [23:0]DT;

    reg [4:0]seq;

    reg [9:0]cnt;
	 reg [27:0]seq_cnt;

    always @(posedge CLK_60 or posedge RST) begin /* 60MHz */
        if (RST) begin
            SCLK <= 1;
            CS <= 0;
            TXD <= 0;
            ACK <= 1;
            DT <= 0;
            cnt <= 0;
            seq <= 0;
				seq_cnt <= 0;
        end else begin
            if (seq == 0) begin
                if (REQ) begin
                    ACK <= 0;
                    SCLK <= 1;
                    CS <= 1;
                    DT <= OUTDATA;
                    cnt[9:5] <= 0;
                    cnt[4:0] <= 5'b10000;
                    seq <= 1;
						  seq_cnt <= seq_cnt + 1;
                end
            end else if (seq == 1) begin
                SCLK <= cnt[4];
                cnt[9:0] <= cnt[9:0] + 1;
                if (cnt[4:0] == 5'b10000) begin /* 60/16/2 -> 1.875Mbps */
                    TXD <= DT[23];
                    DT[23:1] <= DT[22:0];
                    if (cnt[9:5] == 24) begin
                        seq <= 2;
								seq_cnt <= seq_cnt + 1;
                    end
                end
            end else if (seq == 2) begin
                ACK <= 1;
                SCLK <= 1;
                CS <= 0;
                seq <= 0;
					 seq_cnt <= seq_cnt + 1;
            end

        end
    end


endmodule

