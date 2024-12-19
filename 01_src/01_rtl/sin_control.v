
`timescale 1 ns / 10 ps
//////////////////////////////////////////////////////////////////////////////////
// Company: DMT
// Engineer: V
// Create Date: 2024/12/19 09:29
// Design Name: sin_control
// Module Name: sin_control
// Project Name: demo_1st_top
// Target Devices: Control Board V3
// Tool Versions: TD 5.6.2
// Description: encoder data decoding top module
// Dependencies: encoder_control
// Revision:1.0
// Revision 1.01 - File Created
// Additional Comments:
//////////////////////////////////////////////////////////////////////////////////
module sin_control(
// sys input
  input           clk,            // 200MHz clock
  input           rst_n,          // reset
// encoder in
  input           sdo_a,          // adc data input sin
  input           sdo_b,          // adc data input cos
  input           key,            // data acq flag
// encoder out
    output        sincos_clk,     // adc clk output
    output        sincos_cs_n,    // cs_n output
    output [31:0] data_out        // adc angle fir out
);
// wire define
wire [15:0] data_a_out;
wire [15:0] data_b_out;
wire        conv_done;
wire [15:0] sin_out;
wire [15:0] cos_out;
// assgin define
assign data_out = {sin_out,cos_out};
//////////////////////////////////////////////////////////////////////////////////
//                               ADS8350 sample
//////////////////////////////////////////////////////////////////////////////////
ads8350_sample u21_sample(
// sys input
.clk             (clk),           // 200MHz clock
.rst_n           (rst_n),         // reset
// input signal
.key             (key),           // data acq flag
.sdo_a           (sdo_a),         // adc data input sin
.sdo_b           (sdo_b),         // adc data input cos
// output signal
  .sclk          (sincos_clk),    // adc clk output
  .cs_n          (sincos_cs_n),   // cs_n output
  .conv_done     (conv_done),     // adc data ready
  .data_a_out    (data_a_out),    // adc angle data out sin
  .data_b_out    (data_b_out)     // adc angle data out cos
);
//////////////////////////////////////////////////////////////////////////////////
//                                FIR filter
//////////////////////////////////////////////////////////////////////////////////
fir u22_fir(
// sys input
.clk          (clk),           // 200MHz clock
.rst_n        (rst_n),         // reset
// input signal
.clk_en       (conv_done),     // adc data ready
.sin_in       (data_a_out),    // adc angle data out
.cos_in       (data_b_out),    // adc angle data out
// output signal
  .sin_out    (sin_out),       // sin angle fir out
  .cos_out    (cos_out)        // cos angle fir out
);

endmodule
