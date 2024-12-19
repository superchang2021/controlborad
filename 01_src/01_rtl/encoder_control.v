
`timescale 1 ns / 10 ps
//////////////////////////////////////////////////////////////////////////////////
// Company: DMT
// Engineer: V
// Create Date: 2024/12/17 16:01
// Design Name: encoder_control
// Module Name: encoder_control
// Project Name: demo_1st_top
// Target Devices: Control Board V3
// Tool Versions: TD 5.6.2
// Description: encoder data decoding top module
// Dependencies: demo_1st_top
// Revision:1.0
// Revision 1.01 - File Created
// Additional Comments:
//////////////////////////////////////////////////////////////////////////////////
module encoder_control(
// sys interface
  input           clk_200M,       // 200MHz clk    
  input           clk_100M,       // 100MHz clk   
  input           clk_5M,         // 5MHz clk    
  input           rst_n,          // reset    
// signal input
  input     [3:0] key,            // key in    
  input           data_a_in,      // encoder data in a
  input           data_b_in,      // encoder data in b
  input           data_z_in,      // encoder data in z
  input     [4:0] mode,           // encoder mode
  input           sdo_a,          // sin data in
  input           sdo_b,          // cos data in
// signal output  
    output        data_a_out,     // encoder a_data out,defalut as data wire
    output        data_b_out,     // encoder b_data out,defalut as clock wire
    output        data_z_out,     // encoder z_data out
    output        a_out,          // encoder a_out flag
    output        b_out,          // encoder b_out flag 
    output        z_out,          // encoder z_out flag
    output        sincos_clk,     // sincos clk out
    output        sincos_cs_n,    // sincos cs_n out
    output [31:0] data_out        // encoder data out
);
// parameter define
parameter CNT_FREQ = 16'd5000;
// wire define
wire [31:0] abz_data;
wire        data_req;    // encoder data acq flag
// reg define
reg data_a_out_reg;
reg data_b_out_reg;
reg data_z_out_reg;
reg a_out_reg;
reg b_out_reg;
reg z_out_reg;
reg data_abz_a;
reg data_abz_b;
reg data_biss_a;
reg data_ssi_a;
reg data_tawa_a;
reg data_endat_a;

reg data_req_reg;    // encoder data acq flag reg

reg [15:0] timer_100M;

reg rst_n0, rst_n1;    // rst_n reg

reg [31:0] data_out_reg;
// assign define
assign data_a_out = data_a_out_reg;
assign data_b_out = data_b_out_reg;
assign data_z_out = data_z_out_reg;
assign a_out = a_out_reg;
assign b_out = b_out_reg;
assign z_out = z_out_reg;
assign data_req = data_req_reg;
assign data_out = data_out_reg;

//////////////////////////////////////////////////////////////////////////////////
//                              ABZ encoder
//////////////////////////////////////////////////////////////////////////////////
four_sub u10_abz(
// sys input
.clk          (clk_100M),    // 100MHz clk
.rst_n        (rst_n),       // reset
// encoder input
.ain          (data_abz_a),   // encoder data in a
.bin          (data_abz_b),   // encoder data in b
.zin          (1'b0),        // encoder data in z
// angle output
  .sub_cnt    (abz_data[19:0])     // abz data out
);
//////////////////////////////////////////////////////////////////////////////////
//                              BiSS-C encoder
//////////////////////////////////////////////////////////////////////////////////
biss_control u11_biss(
// sys input
.clk           (clk_200M),     // 200MHz clk
.clk_5M        (clk_5M),       // 5MHz clk
.rst_n         (rst_n),        // reset
// input
.key           (data_req),     // encoder data acq flag
.data_in       (data_biss_a),    // biss data input
//output
  .clk_out     (biss_clk),     // biss clk output
  .crc_data    (crc_data),     // biss crc data
  .err_data    (err_data),     // biss error data
  .crc_err     (crc_err),      // crc calc error
  .data_out    (biss_data)     // biss angle data
);
//////////////////////////////////////////////////////////////////////////////////
//                               SSI encoder
//////////////////////////////////////////////////////////////////////////////////
ssi_control u12_ssi(
// sys input
.clk         (clk_200M),     // 200MHz clock
.rst_n       (rst_n0),        // reset
// input
.key         (data_req),     // data request
.data_in     (data_ssi_a),    // ssi data input
// output
.clk_out     (ssi_clk),      // ssi clock output
.data_out    (ssi_data)      // ssi data output
);
//////////////////////////////////////////////////////////////////////////////////
//                               sincos encoder
//////////////////////////////////////////////////////////////////////////////////
sin_control u13_sin(
// sys input
.clk              (clk_200M),       // 100MHz clk
.rst_n            (rst_n0),          // reset
// encoder in
.sdo_a            (sdo_a),          // sin data in
.sdo_b            (sdo_b),          // cos data in
.key              (data_req),       // encoder data acq flag
// encoder out
  .sincos_clk     (sincos_clk),     // sincos clk out
  .sincos_cs_n    (sincos_cs_n),    // sincos cs_n out
  .data_out       (sincos_data)     // sincos data out
);
//////////////////////////////////////////////////////////////////////////////////
//                               tamagawa encoder
//////////////////////////////////////////////////////////////////////////////////
tawa_control u14_tawa(
// / sys input
.clk           (clk_100M),         // 100MHz clk
.rst_n         (rst_n1),            // reset
// input signals
.key           (data_req),         // data acquire trigger
.data_in       (data_tawa_a),        // encoder data in
// out signals
  .RE          (tawa_a_out),       // data output enbale
  .uart_txd    (tawa_data_out),    // encoder data out 
  .data_out    (tawa_data)         // encoder angle data 
);
//////////////////////////////////////////////////////////////////////////////////
//                               endata encoder
//////////////////////////////////////////////////////////////////////////////////
endat_control u15_endat(
// sys input
.clk           (clk_200M),          // 200MHz clk
.rst_n         (rst_n1),            // reset
// input signals
.key           (data_req),          // data acquire trigger
.rx_data       (data_endat_a),         // endata data in
// output signals
  .clk_out     (endat_clk),         // endata clk out
  .clk_en      (endat_clk_en),      // endata clk enable
  .tx_en       (endat_data_en),     // endata data enable
  .tx_dat      (endat_data_out),    // endata data out
  .data_out    (endat_data)         // endata angle data
);
//////////////////////////////////////////////////////////////////////////////////
//                        angle data acq fre control
//////////////////////////////////////////////////////////////////////////////////
always @(posedge clk_100M or negedge rst_n) begin
  if(~rst_n) begin
    data_req_reg <= 1'b0;
    timer_100M <= 16'd0;
  end
  else if( timer_100M == CNT_FREQ ) begin
    data_req_reg <= 1'b1;
    timer_100M <= 16'd0;
  end
  else begin
    data_req_reg <= 1'b0;
    timer_100M <= timer_100M + 1'b1;
  end
end
//////////////////////////////////////////////////////////////////////////////////
//                           encoder mode select
//////////////////////////////////////////////////////////////////////////////////
always @(posedge clk_200M or negedge rst_n)begin
  if(~rst_n) begin
    data_a_out_reg <= 1'b0;
    data_b_out_reg <= 1'b0;
    data_z_out_reg <= 1'b0;
    a_out_reg <= 1'b0;
    b_out_reg <= 1'b0;
    z_out_reg <= 1'b0;
    data_abz_a <= 1'b0;
    data_abz_b <= 1'b0;
    data_biss_a <=  1'b0;
    data_ssi_a <= 1'b0;
    data_tawa_a <= 1'b0;
    data_endat_a <= 1'b0;
  end
// ABZ as just input
  else if(mode==5'b00001)begin
    a_out_reg <= 1'b0;
    b_out_reg <= 1'b0;
    z_out_reg <= 1'b0;
    data_abz_a <= data_a_in;
    data_abz_b <= data_b_in;
    data_out_reg <= abz_data;
  end
// BiSS-C as a input, b output
  else if(mode==5'b00010)begin
    b_out_reg <= 1'b1;
    data_b_out_reg <= biss_clk;
    data_out_reg <= biss_data;
    data_biss_a <= data_a_in;
  end
// SSI as a input, b output
  else if(mode==5'b00100)begin
    b_out_reg <= 1'b1;
    data_b_out_reg <= ssi_clk;
    data_out_reg <= ssi_data;
    data_ssi_a <= data_a_in;
  end
// tawagama as a inout,b not used
  else if(mode==5'b01000)begin
    a_out_reg <= tawa_a_out;
    data_a_out_reg <= tawa_data_out;
    data_out_reg <= tawa_data;
    data_tawa_a <= data_a_in;
  end
// EnDat as a inout, b output
  else if(mode==5'b10000)begin
    a_out_reg <= endat_data_en;
    data_a_out_reg <= endat_data_out;
    b_out_reg <= endat_clk_en;
    data_b_out_reg <= endat_clk;
    data_out_reg <= endat_data;
    data_endat_a <= data_a_in;
  end
  else if(mode==5'b00000)begin
    data_out_reg <= sincos_data;
  end
  else begin
    data_a_out_reg <= 1'b0;
    data_b_out_reg <= 1'b0;
    data_z_out_reg <= 1'b0;
    a_out_reg <= 1'b0;
    b_out_reg <= 1'b0;
    z_out_reg <= 1'b0;
    data_abz_a <= 1'b0;
    data_abz_b <= 1'b0;
    data_biss_a <=  1'b0;
    data_ssi_a <= 1'b0;
    data_tawa_a <= 1'b0;
    data_endat_a <= 1'b0;
  end
end
//////////////////////////////////////////////////////////////////////////////////
//                           reset signal high fanout
//////////////////////////////////////////////////////////////////////////////////
always @(posedge clk_100M) begin
  if(~rst_n) begin
    rst_n0 <= 1'b0;
    rst_n1 <= 1'b0;
  end
  else begin
    rst_n0 <= rst_n;
    rst_n1 <= rst_n0;
  end
end

// biss-c 角度数据30kHz(20KHz)，33330ns(50000ns)，100MHz时钟计数3333次(5000次)，CNT_FREQ=3333


endmodule
