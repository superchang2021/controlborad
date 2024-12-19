
`timescale 1 ns / 10 ps
//////////////////////////////////////////////////////////////////////////////////
// Company: DMT INTELLIGENT EQUIPMENT TECHNOLOGY CO., LTD.
// Engineer: V
// Create Date: 2024/12/17 10:20
// Design Name: emif_control
// Module Name: emif_control
// Project Name: demo_1st_top
// Target Devices: Control Board V3
// Tool Versions: TD 5.6.2
// Description: control emif read/write
// Dependencies: demo_1st_top
// Revision:1.0
// Revision 1.01 - File Created
// Additional Comments: wren & rden were not used now
//////////////////////////////////////////////////////////////////////////////////
module emif_control(
// sys input
  input           clk,          // 200MHz clk
  input           rst_n,        // reset
// emif input signal
  input           emif_clk,     // EMIF clock sync
  input           emif_cke,     // EMIF clock enable  sync output
  input           emif_ce,      // EMIF chip enable sync output 
  input           wr_en,        // replace emif_we to dis read & write
  input           rd_en,        // replace emif_we to dis read & write
  input           emif_cas,     // EMIF sync cas
  input           emif_ras,     // EMIF sync ras
  input           emif_dqm0,    // EMIF dqm0
  input           emif_dqm1,    // EMIF dqm1
  input    [12:0] emif_addr,    // EMIF address
// emif output signal
    output [12:0] row_addr,     // EMIF row address
    output [12:0] col_addr,     // EMIF column address
    output        fpga_read,    // FPGA read enable
    output        fpga_write    // FPGA write enable
);
// reg define
reg        fpga_read_reg;     // FPGA read enable reg
reg        fpga_write_reg;    // FPGA write enable reg 
reg [12:0] row_addr_reg;      // EMIF row address reg
reg [12:0] col_addr_reg;      // EMIF column address reg
// assign define
assign  fpga_read = fpga_read_reg;
assign fpga_write = fpga_write_reg;
assign   row_addr = row_addr_reg;
assign   col_addr = col_addr_reg;
//////////////////////////////////////////////////////////////////////////////////
//                         read/write generate module
//////////////////////////////////////////////////////////////////////////////////
always @(posedge clk or negedge rst_n) begin
  if(~rst_n) begin
    fpga_read_reg <= 1'b0;
    fpga_write_reg <= 1'b0;
  end
// using welogic and rac/cas
  else if({wr_en,emif_cas}==2'b00) begin
    fpga_read_reg <= 1'b1;
    fpga_write_reg <= 1'b0;
  end
  else if({rd_en,emif_cas}==2'b00) begin
    fpga_write_reg <= 1'b1;
    fpga_read_reg <= 1'b0;
  end
//  清零
  else begin
    fpga_read_reg <= 1'b0;
    fpga_write_reg <= 1'b0;
  end
end
//////////////////////////////////////////////////////////////////////////////////
//                         address generate module
//////////////////////////////////////////////////////////////////////////////////
always @(posedge clk or negedge rst_n) begin
  if(~rst_n) begin
    row_addr_reg <= 13'd0;
    col_addr_reg <= 13'd0;
  end
  else if(~emif_ras) begin
    row_addr_reg <= emif_addr;
  end
  else if(~emif_cas) begin
    col_addr_reg <= emif_addr;
  end
  else begin
    row_addr_reg <= row_addr_reg;
    col_addr_reg <= col_addr_reg;
  end
end

endmodule
