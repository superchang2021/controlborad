
`timescale 1 ns / 10 ps
//////////////////////////////////////////////////////////////////////////////////
// Company: DMT
// Engineer: V
// Create Date: 2024/12/19 14:21
// Design Name: tawa_control
// Module Name: tawa_control
// Project Name: demo_1st_top
// Target Devices: Control Board V3
// Tool Versions: TD 5.6.2
// Description: encoder data decoding top module
// Dependencies: encoder_control
// Revision:1.0
// Revision 1.01 - File Created
// Additional Comments:
//////////////////////////////////////////////////////////////////////////////////
module tawa_control(
// sys signals
  input           clk,         // 100MHz clk
  input           rst_n,       // reset
// input signals
  input           key,         // data acquire trigger
  input           data_in,     // encoder data in
// output signals
    output        RE,          // data output enbale
    output        uart_txd,    // encoder data out 
    output [31:0] data_out     // encoder angle data 
);
// wire define
wire        uart_done;        // uart recive complete
wire        uart_send_en;     // uart send enable
wire  [7:0] uart_data_in;     // uart receive data
wire  [7:0] uart_data_out;    // uart send data
wire  [7:0] crc_calc;         // CRC calc data
wire  [7:0] SF_data;          // SF data
wire  [7:0] REQUEST;          // request data
wire  [7:0] ENID;             // encoder ID
wire  [7:0] ALMC;             // ALMC data
wire [23:0] turn_data;        // turn data
wire        tx_flag;          // data output enbale
wire [23:0] angle_uart;       // encoder angle data 
// assign define
assign RE = tx_flag;
assign data_out = {crc_calc,angle_uart};
//////////////////////////////////////////////////////////////////////////////////
//                               uart control
//////////////////////////////////////////////////////////////////////////////////
uart_control u31_uart_control(
//system
.clk             (clk),         // clk 100MHz
.rst_n           (rst_n),            // resset
//input
.data_in         (uart_data_in),     // uart receive data
.flag_recv       (uart_done),        // uart recive complete
.key_in          (key),              // data acq trigger
//output
  .data_out      (uart_data_out),    // data send to encoder
	.angle_uart    (angle_uart),       // angle data recive from encoder
  .SF_data_out   (SF_data),          // SF angle data recive from encoder
  .ALMC_out      (ALMC),             // ALMC data recive from encoder
  .turn_data_out (turn_data),        // turn data recive from encoder
  .ENID_out      (ENID),             // ENID data recive from encoder
  .REQUEST_out   (REQUEST),          // data send to encoder to acq data
  .flag_send     (uart_send_en)      // uart send enable
);
//////////////////////////////////////////////////////////////////////////////////
//                               uart recive
//////////////////////////////////////////////////////////////////////////////////
uart_recv u32_uart_recv(
//system
.clk             (clk),       // clk 100MHz
.rst_n           (rst_n),          // reset
//input
.uart_rxd        (data_in),        // encoder data in
//output
  .uart_done     (uart_done),      // uart recive complete
  .uart_data     (uart_data_in)    // uart receive data
);
//////////////////////////////////////////////////////////////////////////////////
//                               uart send
//////////////////////////////////////////////////////////////////////////////////
uart_send u33_uart_send(
//system
.clk            (clk),         // clk 100MHz
.rst_n          (rst_n),            // reset
//input
.uart_data      (uart_data_out),    // data send to encoder
.uart_send_en   (uart_send_en),     // uart send enable
//output
  .tx_flag      (tx_flag),          // data output enbale
	.uart_txd     (uart_txd)          // encoder data out 
);
//////////////////////////////////////////////////////////////////////////////////
//                               CRC calc
//////////////////////////////////////////////////////////////////////////////////
crc_calc u34_crc(
// sys input
.clk           (clk),     // clk 100MHz
.rst_n         (rst_n),        // reset
// input data
.angle_data    (angle_uart),   // 24bit angle data
.REQUEST       (REQUEST),      // 8bit request data
.SF_data       (SF_data),      // 8bit SF data
.ALMC          (ALMC),         // 8bit ALMC
.ENID          (ENID),         // 8bit encoder ID
.turn_data     (turn_data),    // 24bit turn data
// output
  .crc_calc    (crc_calc)      // CRC calc data
);

endmodule
