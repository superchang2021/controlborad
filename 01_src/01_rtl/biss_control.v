
`timescale 1 ns / 10 ps
//////////////////////////////////////////////////////////////////////////////////
// Company: DMT
// Engineer: V
// Create Date: 2024/12/17 17:24
// Design Name: biss_control
// Module Name: biss_control
// Project Name: demo_1st_top
// Target Devices: Control Board V3
// Tool Versions: TD 5.6.2
// Description: encoder data decoding top module
// Dependencies: encoder_control
// Revision:1.0
// Revision 1.01 - File Created
// Additional Comments:
//////////////////////////////////////////////////////////////////////////////////
module biss_control(
// sys input
  input           clk,          // 200MHz clk
  input           clk_5M,       // 5MHz clk
  input           rst_n,        // reset
// biss input 
  input           data_in,      // biss data input
  input           key,          // data request
// biss output 
    output        clk_out,      // biss clk output
    output        crc_err,      // crc calc error
    output  [1:0] err_data,     // biss error data
    output  [5:0] crc_data,     // biss crc data
    output [25:0] data_out      // biss angle data
);
// parameter define  
parameter    IDLE = 4'b0001;    // state define
parameter    ACK  = 4'b0010;    // state define
parameter    STR  = 4'b0100;    // state define
parameter    STP  = 4'b1000;    // state define
parameter CNT_PLL = 8'd49;      // 2MHz cnt using 200MHz clk
// wire define
wire       IDLE2ACK_start;      // state shift condition
wire       ACK2STR_start;       // state shift condition
wire       STR2STP_start;       // state shift condition
wire       STP2IDLE_start;      // state shift condition
wire       clk_out_rev;         // biss clk output (reverse)
wire [5:0] crc_outt;            // crc calc result
// reg define
reg  [3:0] state_c;             // state current
reg  [3:0] state_n;             // state next
reg        flag_ACK;            // state shift flag
reg        flag_STR;            // state shift flag
reg        flag_STP;            // state shift flag
reg        flag_IDLE;           // state shift flag
reg [11:0] cnt_clk;             // 2MHz cnt
reg        clk_2M;              // 2MHz clk
reg        cnt_2M_reg0;         // 2MHz register
reg        cnt_2M_reg1;         // 2MHz register
reg        pose_clk_2MHz;       // 2MHz clk first pos
reg        request;             // biss start flag
reg        clk_out_reg;         // biss clk output reg
reg        clk_out_reg0;        // biss clk output reg
reg        clk_out_reg1;        // biss clk output reg
reg        data_in_reg0;        // biss data input reg
reg        data_in_reg1;        // biss data input reg
reg  [7:0] STR_cntclk;          // STR state clk counter
reg  [7:0] STR_cntclkdown;      // STR state clk negedge counter
reg [25:0] angle;               // biss angle data processing reg
reg [25:0] data_out_reg;        // biss angle data reg
reg  [5:0] crc_data_reg;        // biss crc data reg
reg  [1:0] error;               // biss error flag reg
reg  [5:0] data_crc;            // biss crc data processing reg
reg        crc_en;              // crc enable
reg        read_done;           // biss data read done
reg        crc_done;            // crc data done
reg        crc_err_reg;         // crc error reg
reg        read_done0;          // biss data read done reg
reg        read_done1;          // biss data read done reg
reg  [7:0] calc_i5;             // crc calc reg
reg  [7:0] calc_i4;             // crc calc reg
reg  [7:0] calc_i3;             // crc calc reg
reg  [7:0] calc_i2;             // crc calc reg
reg  [7:0] calc_i1;             // crc calc reg
reg [31:0] calc_crc;            // crc calc reg
reg  [7:0] cnt_en;              // CRC clac timer
reg [31:0] CRC_TABLE [0:64];    // CRC calc table
// assign define
assign IDLE2ACK_start  = (state_c == IDLE) && flag_ACK;     // define state change signal
assign ACK2STR_start   = (state_c == ACK)  && flag_STR;     // define state change signal
assign STR2STP_start   = (state_c == STR)  && flag_STP;     // define state change signal
assign STP2IDLE_start  = (state_c == STP)  && flag_IDLE;    // define state change signal
assign    data_out = data_out_reg;
assign    clk_out  = clk_out_reg;
assign    crc_data = crc_data_reg;
assign clk_out_rev = ~clk_out_reg1;
assign    err_data = error;
assign     crc_err = crc_err_reg;
assign    crc_outt = calc_crc[5:0];
//////////////////////////////////////////////////////////////////////////////////
//                                2MHz generator
//////////////////////////////////////////////////////////////////////////////////
always @(posedge clk or negedge rst_n) begin
  if(~rst_n) begin
    clk_2M  <= 1'b1;
    cnt_clk <= 12'd0;
  end
  else if(cnt_clk == CNT_PLL) begin
    clk_2M  <= ~clk_2M;
    cnt_clk <= 12'd0;
  end
  else begin
    clk_2M  <= clk_2M;
    cnt_clk <= cnt_clk + 1'b1;
  end
end
//////////////////////////////////////////////////////////////////////////////////
//                      2MHz\5MHz\biss_clk\biss_data latch
//////////////////////////////////////////////////////////////////////////////////
always @(posedge clk or negedge rst_n) begin
  if(~rst_n) begin
    cnt_2M_reg0  <= 1'b1;
    cnt_2M_reg1  <= 1'b1;
    clk_out_reg0 <= 1'b1;
    clk_out_reg1 <= 1'b1;
    data_in_reg0 <= 1'b1;
    data_in_reg1 <= 1'b1;
    read_done0   <= 1'b0;
    read_done1   <= 1'b0;
  end
  else begin
    cnt_2M_reg0  <= clk_2M;
    cnt_2M_reg1  <= cnt_2M_reg0;
    clk_out_reg0 <= clk_out_reg;
    clk_out_reg1 <= clk_out_reg0;
    data_in_reg0 <= data_in;
    data_in_reg1 <= data_in_reg0;
    read_done0   <= read_done;
    read_done1   <= read_done0;
  end
end
//////////////////////////////////////////////////////////////////////////////////
//                             encoder data request 
//////////////////////////////////////////////////////////////////////////////////
always @(posedge clk or negedge rst_n) begin
  if(~rst_n) begin
    request <= 1'b0;
  end
// data request set by key
  else if(key) begin
    request <= 1'b1;
  end
  else if(flag_IDLE) begin
    request <= 1'b0;
  end
  else begin
    request <= request;
  end
end
//////////////////////////////////////////////////////////////////////////////////
//                              BiSS clk output
//////////////////////////////////////////////////////////////////////////////////
always @(posedge clk or negedge rst_n) begin
  if(~rst_n) begin
    pose_clk_2MHz <= 1'b0;
  end
// at the first rising edge of clk_2MHz,set pose_clk_2MHz high
  else if({request,cnt_2M_reg0,cnt_2M_reg1} == 3'b110) begin
    pose_clk_2MHz <= 1'b1;
  end
  else if(~request) begin
    pose_clk_2MHz <= 1'b0;
  end
  else begin
    pose_clk_2MHz <= pose_clk_2MHz;
  end
end
always @(posedge clk or negedge rst_n) begin
  if(~rst_n) begin
    clk_out_reg <= 1'b1;
  end
// STP state,set clk_out_reg high
  else if(state_c == STP) begin
    clk_out_reg <= 1'b1;
  end
// when pose_clk_2MHz = 1，2MHz output
  else if(pose_clk_2MHz) begin
    clk_out_reg <= clk_2M;
  end
  else begin
    clk_out_reg <= 1'b1;
  end
end
//////////////////////////////////////////////////////////////////////////////////
//                              state flag generator
//////////////////////////////////////////////////////////////////////////////////
always @(posedge clk or negedge rst_n) begin
  if(~rst_n) begin
    flag_ACK <= 1'b0;
  end
// IDLE state,the first data_in falling edge is the start of ACK state 
  else if(({data_in_reg0,data_in_reg1} == 2'b01) && state_c == IDLE) begin
    flag_ACK <= 1'b1;
  end
  else begin
    flag_ACK <= 1'b0;
  end
end

always @(posedge clk or negedge rst_n) begin
  if(~rst_n) begin
    flag_STR <= 1'b0;
  end
// ACK state,the first data_in rising edge is the start of STR state
  else if(({data_in_reg0,data_in_reg1} == 2'b10) && state_c == ACK) begin
    flag_STR <= 1'b1;
  end
  else begin
    flag_STR <= 1'b0;
  end
end

always @(posedge clk or negedge rst_n) begin
  if(~rst_n) begin
    flag_STP <= 1'b0;
  end
// STR state,the first clk_out rising edge is the start of STP state
  else if(STR_cntclk == 8'd37 && state_c == STR) begin
    flag_STP <= 1'b1;
  end
  else begin
    flag_STP <= 1'b0;
  end
end

always @(posedge clk or negedge rst_n) begin
  if(~rst_n) begin
    flag_IDLE <= 1'b0;
  end
// STP state,the first data_in rising edge is the start of IDLE state
  else if(state_c == STP && {data_in_reg0,data_in_reg1} == 2'b10) begin
    flag_IDLE <= 1'b1;
  end
  else begin
    flag_IDLE <= 1'b0;
  end
end
//////////////////////////////////////////////////////////////////////////////////
//                              sync always block
//////////////////////////////////////////////////////////////////////////////////
always @(posedge clk or negedge rst_n) begin
  if(~rst_n) begin
    state_c <= IDLE;
  end
  else begin
    state_c <= state_n;
  end
end
//////////////////////////////////////////////////////////////////////////////////
//                           combinational logic block
//////////////////////////////////////////////////////////////////////////////////
always @(*) begin
  case(state_c)
    IDLE:begin
      if(IDLE2ACK_start) begin
        state_n <= ACK;
      end
      else begin
        state_n <= state_c;
      end
    end
    ACK:begin
      if(ACK2STR_start) begin
        state_n <= STR;
      end
      else begin
        state_n <= state_c;
      end
    end
    STR:begin
      if(STR2STP_start) begin
        state_n <= STP;
      end
      else begin
        state_n <= state_c;
      end
    end
    STP:begin
      if(STP2IDLE_start) begin
        state_n <= IDLE;
      end
      else begin
        state_n <= state_c;
      end
    end
    default:begin
      state_n <= IDLE;
    end
  endcase
end
//////////////////////////////////////////////////////////////////////////////////
//                           state machine cnter
//////////////////////////////////////////////////////////////////////////////////
always @(posedge clk or negedge rst_n) begin
  if(~rst_n) begin
    STR_cntclk     <= 8'd0;
    STR_cntclkdown <= 8'd0;
  end
  else if(flag_IDLE) begin
    STR_cntclk     <= 8'd0;
    STR_cntclkdown <= 8'd0;
  end
// STP state,count the number of clk_out falling edge
  else if (state_c == STR && ({clk_out_reg0,clk_out_reg1} == 2'b10))begin
    STR_cntclk <= STR_cntclk + 1'b1;
  end
  else if (state_c == STR && ({clk_out_reg0,clk_out_reg1} == 2'b01)) begin
    STR_cntclkdown <= STR_cntclkdown + 1'b1;
  end
  else begin
    STR_cntclk     <= STR_cntclk;
    STR_cntclkdown <= STR_cntclkdown;
  end
end
//////////////////////////////////////////////////////////////////////////////////
//                         state machine output data
//////////////////////////////////////////////////////////////////////////////////
always @(posedge clk_out_rev or negedge rst_n) begin
  if(~rst_n) begin
    angle     <= 26'd0;
    data_crc  <= 6'd0;
    error     <= 2'b11;
    read_done <= 1'b0;
    crc_done  <= 1'b0;
  end
// STR state,save the data using STR_cntclk
  else begin
    case(STR_cntclk)
      3:begin
        angle[25] <= data_in_reg1;
      end
      4:begin
        angle[24] <= data_in_reg1;
      end
      5:begin
        angle[23] <= data_in_reg1;
      end
      6:begin
        angle[22] <= data_in_reg1;
      end
      7:begin
        angle[21] <= data_in_reg1;
      end
      8:begin
        angle[20] <= data_in_reg1;
      end
      9:begin
        angle[19] <= data_in_reg1;
      end
      10:begin
        angle[18] <= data_in_reg1;
      end
      11:begin
        angle[17] <= data_in_reg1;
      end
      12:begin
        angle[16] <= data_in_reg1;
      end
      13:begin
        angle[15] <= data_in_reg1;
      end
      14:begin
        angle[14] <= data_in_reg1;
      end
      15:begin
        angle[13] <= data_in_reg1;
      end
      16:begin
        angle[12] <= data_in_reg1;
      end
      17:begin
        angle[11] <= data_in_reg1;
      end
      18:begin
        angle[10] <= data_in_reg1;
      end
      19:begin
        angle[9] <= data_in_reg1;
      end
      20:begin
        angle[8] <= data_in_reg1;
      end
      21:begin
        angle[7] <= data_in_reg1;
      end
      22:begin
        angle[6] <= data_in_reg1;
      end
      23:begin
        angle[5] <= data_in_reg1;
      end
      24:begin
        angle[4] <= data_in_reg1;
      end
      25:begin
        angle[3] <= data_in_reg1;
      end
      26:begin
        angle[2] <= data_in_reg1;
      end
      27:begin
        angle[1] <= data_in_reg1;
      end
      28:begin
        angle[0] <= data_in_reg1;
      end
      29:begin
        error[1] <= data_in_reg1;
      end
      30:begin
        error[0] <= data_in_reg1;
        read_done <= 1'b1;
      end
      31:begin
        data_crc[5] <= ~data_in_reg1;
        read_done <= 1'b0;
      end
      32:begin
        data_crc[4] <= ~data_in_reg1;
      end
      33:begin
        data_crc[3] <= ~data_in_reg1;
      end
      34:begin
        data_crc[2] <= ~data_in_reg1;
      end
      35:begin
        data_crc[1] <= ~data_in_reg1;
      end
      36:begin
        data_crc[0] <= ~data_in_reg1;
        crc_done <= 1'b1;
      end
      default:begin
        angle     <= angle;
        error     <= error;
        data_crc  <= data_crc;
        read_done <= read_done;
        crc_done  <= 1'b0;
      end
    endcase
  end
end
//////////////////////////////////////////////////////////////////////////////////
//                           crc_en generation
//////////////////////////////////////////////////////////////////////////////////
always@ (posedge clk or negedge rst_n) begin
  if(~rst_n) begin
    crc_en <= 1'b0;
  end
  else if({read_done0,read_done1 == 2'b10}) begin
    crc_en <= 1'b1;
  end
  else begin
    crc_en <= 1'b0;
  end
end
//////////////////////////////////////////////////////////////////////////////////
//                             biss data output 
//////////////////////////////////////////////////////////////////////////////////
always@(posedge clk or negedge rst_n) begin
  if(~rst_n)begin
    data_out_reg <= 26'd0;
  end
  else if(read_done) begin
    data_out_reg <= angle;
  end
  else begin
    data_out_reg <= data_out_reg;
  end
end
//////////////////////////////////////////////////////////////////////////////////
//                        CRC check table initialization
//////////////////////////////////////////////////////////////////////////////////
always @(posedge clk) begin
  CRC_TABLE[0]  <= 32'h00;
  CRC_TABLE[1]  <= 32'h03;
  CRC_TABLE[2]  <= 32'h06;
  CRC_TABLE[3]  <= 32'h05;
  CRC_TABLE[4]  <= 32'h0c;
  CRC_TABLE[5]  <= 32'h0f;
  CRC_TABLE[6]  <= 32'h0a;
  CRC_TABLE[7]  <= 32'h09;

  CRC_TABLE[8]  <= 32'h18;
  CRC_TABLE[9]  <= 32'h1b;
  CRC_TABLE[10] <= 32'h1e;
  CRC_TABLE[11] <= 32'h1d;
  CRC_TABLE[12] <= 32'h14;
  CRC_TABLE[13] <= 32'h17;
  CRC_TABLE[14] <= 32'h12;
  CRC_TABLE[15] <= 32'h11;

  CRC_TABLE[16] <= 32'h30;
  CRC_TABLE[17] <= 32'h33;
  CRC_TABLE[18] <= 32'h36;
  CRC_TABLE[19] <= 32'h35;
  CRC_TABLE[20] <= 32'h3c;
  CRC_TABLE[21] <= 32'h3f;
  CRC_TABLE[22] <= 32'h3a;
  CRC_TABLE[23] <= 32'h39;

  CRC_TABLE[24] <= 32'h28;
  CRC_TABLE[25] <= 32'h2b;
  CRC_TABLE[26] <= 32'h2e;
  CRC_TABLE[27] <= 32'h2d;
  CRC_TABLE[28] <= 32'h24;
  CRC_TABLE[29] <= 32'h27;
  CRC_TABLE[30] <= 32'h22;
  CRC_TABLE[31] <= 32'h21;

  CRC_TABLE[32] <= 32'h23;
  CRC_TABLE[33] <= 32'h20;
  CRC_TABLE[34] <= 32'h25;
  CRC_TABLE[35] <= 32'h26;
  CRC_TABLE[36] <= 32'h2f;
  CRC_TABLE[37] <= 32'h2c;
  CRC_TABLE[38] <= 32'h29;
  CRC_TABLE[39] <= 32'h2a;

  CRC_TABLE[40] <= 32'h3b;
  CRC_TABLE[41] <= 32'h38;
  CRC_TABLE[42] <= 32'h3d;
  CRC_TABLE[43] <= 32'h3e;
  CRC_TABLE[44] <= 32'h37;
  CRC_TABLE[45] <= 32'h34;
  CRC_TABLE[46] <= 32'h31;
  CRC_TABLE[47] <= 32'h32;

  CRC_TABLE[48] <= 32'h13;
  CRC_TABLE[49] <= 32'h10;
  CRC_TABLE[50] <= 32'h15;
  CRC_TABLE[51] <= 32'h16;
  CRC_TABLE[52] <= 32'h1f;
  CRC_TABLE[53] <= 32'h1c;
  CRC_TABLE[54] <= 32'h19;
  CRC_TABLE[55] <= 32'h1a;

  CRC_TABLE[56] <= 32'h0b;
  CRC_TABLE[57] <= 32'h08;
  CRC_TABLE[58] <= 32'h0d;
  CRC_TABLE[59] <= 32'h0e;
  CRC_TABLE[60] <= 32'h07;
  CRC_TABLE[61] <= 32'h04;
  CRC_TABLE[62] <= 32'h01;
  CRC_TABLE[63] <= 32'h02;
end
//////////////////////////////////////////////////////////////////////////////////
//                             CRC start counter
//////////////////////////////////////////////////////////////////////////////////
always @(posedge clk or negedge rst_n) begin
  if(~rst_n) begin
    cnt_en <= 8'd0;
  end
  else if(crc_en) begin
    cnt_en <= 8'd1;
  end
  else if (cnt_en >= 8'd1 && cnt_en <= 10)begin
    cnt_en <= cnt_en + 8'd1;
  end
  else begin
    cnt_en <= 8'd0;
  end
end
//////////////////////////////////////////////////////////////////////////////////
//                                 CRC calc
//////////////////////////////////////////////////////////////////////////////////
always @(posedge clk or negedge rst_n) begin
  if(~rst_n) begin
    calc_i1 <= 8'd0;
    calc_i2 <= 8'd0;
    calc_i3 <= 8'd0;
    calc_i4 <= 8'd0;
    calc_i5 <= 8'd0;
  end
// using datasheet calc logic in C language
  else begin
    case(cnt_en)
      1:begin
        calc_i1 <= ((data_out_reg >> 24) & 32'h3f) ^ 32'h0;
      end
      3:begin
        calc_i2 <= ((data_out_reg >> 18) & 32'h3f) ^ CRC_TABLE[calc_i1];
      end
      5:begin
        calc_i3 <= ((data_out_reg >> 12) & 32'h3f) ^ CRC_TABLE[calc_i2];
      end
      7:begin
        calc_i4 <= ((data_out_reg >> 6)  & 32'h3f) ^ CRC_TABLE[calc_i3];
      end
      9:begin
        calc_i5 <= (      data_out_reg   & 32'h3f) ^ CRC_TABLE[calc_i4];
      end
      default:begin
        calc_i1 <= calc_i1;
        calc_i2 <= calc_i2;
        calc_i3 <= calc_i3;
        calc_i4 <= calc_i4;
        calc_i5 <= calc_i5;
      end
    endcase
  end
end
//////////////////////////////////////////////////////////////////////////////////
//                              CRC calc output
//////////////////////////////////////////////////////////////////////////////////
always @(posedge clk) begin
  calc_crc <= CRC_TABLE[calc_i5];
end
//////////////////////////////////////////////////////////////////////////////////
//                                CRC results
//////////////////////////////////////////////////////////////////////////////////
always@(posedge clk or negedge rst_n) begin
  if(~rst_n)begin
    crc_data_reg <= 6'd0;
    crc_err_reg  <= 1'b0;
  end
  else if(crc_done) begin
    crc_data_reg <= data_crc;
    if(crc_outt == crc_data_reg) begin
      crc_err_reg <= 1'b0;
    end
    else begin
      crc_err_reg <= 1'b1;
    end
  end
  else begin
    crc_data_reg <= crc_data_reg;
    crc_err_reg  <= crc_err_reg;
  end
end

endmodule
