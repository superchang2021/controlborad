
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
module endat_control(
// sys signals
  input           clk,        // 200MHz clk
  input           rst_n,      // reset
// input siganls
  input           key,        // data acquire trigger
  input           rx_data,    // endata data in
// output signals
    output        clk_out,    // endata clk out
    output        clk_en,     // endata clk enable
    output        tx_en,      // endata data enable
    output        tx_dat,     // endata data out
    output [31:0] data_out    // endata angle data
);
// wire define
wire        data_mi;
wire        locked;
wire        flag_out;
wire [20:0] data_angle;
// assign define
assign   tx_dat = data_mi;
assign   clk_en = 1'b1;
assign    tx_en = flag_out;
assign data_out = data_angle;
//////////////////////////////////////////////////////////////////////////////////
//                               endat_control
//////////////////////////////////////////////////////////////////////////////////
endat_contol_sample u41_control(
// sys input
.clk             (clk),          // 200MHz clk
.rst_n           (rst_n),        // reset
// input
.key             (key),          // data acquire trigger
.data_in         (rx_data),      // endata data in
.clk_out         (clk_out),      // endata clk out
//output
  .flag_out      (flag_out),     // endata data enable
  .data_mi       (data_mi),      // endata data out
  .data_angle    (data_angle)    // endata angle data
);

endmodule
