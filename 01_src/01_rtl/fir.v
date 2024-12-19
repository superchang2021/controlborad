
`timescale 1 ns / 10 ps
//////////////////////////////////////////////////////////////////////////////////
// Company: DMT
// Engineer: V
// Create Date: 2024/12/19 10:03
// Design Name: fir
// Module Name: fir
// Project Name: demo_1st_top
// Target Devices: Control Board V3
// Tool Versions: TD 5.6.2
// Description: encoder data decoding top module
// Dependencies: sin_control
// Revision:1.0
// Revision 1.01 - File Created
// Additional Comments:
//////////////////////////////////////////////////////////////////////////////////
module fir(
// sys signals
  input           clk,        // 200MHz clock
  input           rst_n,      // reset
// data signals input
  input           clk_en,     // data enbale
  input    [15:0] sin_in,     // sin data in
  input    [15:0] cos_in,     // cos data in
// output signals
    output [15:0] sin_out,    // sin data fir out
    output [15:0] cos_out     // cos data fir out
);
// wire define
wire [34:0] cos_out_long;
wire [34:0] sin_out_long;
// assign define
assign cos_out = cos_out_long[34:18];
assign sin_out = sin_out_long[34:18];
//////////////////////////////////////////////////////////////////////////////////
//                                sin filter
//////////////////////////////////////////////////////////////////////////////////
filter_verilog U1_fir(
// sys input
.clk             (clk),            // 200MHz clock
.rst_n           (rst_n),          // reset
// data input
.clk_enable      (clk_en),         // data enbale
.filter_in       (sin_in),         // 16bit data in
// data output
  .filter_out    (sin_out_long)    // 34bit fir data out
);
//////////////////////////////////////////////////////////////////////////////////
//                                cos filter
//////////////////////////////////////////////////////////////////////////////////
filter_verilog U2_fir(
// sys input
.clk             (clk),            // 200MHz clock
.rst_n           (rst_n),          // reset
// data input
.clk_enable      (clk_en),         // data enbale
.filter_in       (cos_in),         // 16bit data in
//data output
  .filter_out    (cos_out_long)    // 34bit fir data out
);

endmodule
