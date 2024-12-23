
`timescale 1 ns / 10 ps
//////////////////////////////////////////////////////////////////////////////////
// Company: DMT
// Engineer: V
// Create Date: 2024/12/16 16:39
// Design Name: emif_read
// Module Name: emif_read
// Project Name: demo_1st_top
// Target Devices: Control Board V3
// Tool Versions: TD 5.6.2
// Description: save data in 5 clk after we logic
// Dependencies: demo_1st_top
// Revision:1.0
// Revision 1.01 - File Created
// Additional Comments:
//////////////////////////////////////////////////////////////////////////////////
module emif_read(
// sys input
  input           clk,             // 200MHz
  input           rst_n,           // reset
// emif input
  input           read_en,         // EMIF we logic
  input    [12:0] emif_addr,       // EMIF address
  input    [15:0] data_in,         // EMIF data in
// data output
    output  [4:0] encoder_mode,    // encoder mode
    output        read_done,       // read done reg
    output [15:0] fpga_read        // FPGA read data
);
/**********  reg define  ***********/
reg  [4:0] encoder_mode_reg;    // encoder mode reg
reg        read_done_reg;       // read done reg
reg [15:0] fpga_read_reg;       // FPGA read data reg
reg  [3:0] cnt_en;              // read start cnt
reg [15:0] mcu_data [7:0];      // restore data from emif
reg [12:0] emif_addr_reg0;
reg [12:0] emif_addr_reg1;
reg [15:0] data_in_reg0;
reg [15:0] data_in_reg1;
/**********  assign define  ***********/
assign encoder_mode = encoder_mode_reg;
assign fpga_read = fpga_read_reg;
assign read_done = read_done_reg;
//////////////////////////////////////////////////////////////////////////////////
//                             fpga catch module
//////////////////////////////////////////////////////////////////////////////////
always @(posedge clk or negedge rst_n) begin
  if(~rst_n) begin
    emif_addr_reg0 <= 13'd0;
    emif_addr_reg1 <= 13'd0;
    data_in_reg0 <= 16'd0;
    data_in_reg1 <= 16'd0;
  end
  else begin
    emif_addr_reg0 <= emif_addr;
    emif_addr_reg1 <= emif_addr_reg0;
    data_in_reg0   <= data_in;
    data_in_reg1   <= data_in_reg0;
  end
end
//////////////////////////////////////////////////////////////////////////////////
//                             fpga read module
//////////////////////////////////////////////////////////////////////////////////
always @(posedge clk or negedge rst_n) begin
  if(~rst_n) begin
    fpga_read_reg <= 16'd0;
    cnt_en        <= 4'd0;
    read_done_reg <= 1'b0;
  end
// input data at 5 clk before read_en
  else if( read_en && cnt_en <= 4'd4 ) begin
    cnt_en        <= cnt_en + 1'b1;
  end
  else if( read_en && cnt_en == 4'd5 ) begin
    fpga_read_reg <= data_in_reg1;
    cnt_en        <= cnt_en + 1'b1;
    read_done_reg <= 1'b1;
  end
// when read_en =0 ,clear all
  else if ( ~read_en ) begin
    fpga_read_reg <= 16'd0;
    cnt_en        <= 4'd0;
    read_done_reg <= 1'b0;
  end
  else begin
    fpga_read_reg <= 16'd0;
    cnt_en        <= 4'd0;
    read_done_reg <= 1'b0;
  end
end
//////////////////////////////////////////////////////////////////////////////////
//                         fpga read data save module
//////////////////////////////////////////////////////////////////////////////////
always @(posedge clk or negedge rst_n) begin
  if(~rst_n) begin
    mcu_data[0] <= 16'd0;
    mcu_data[1] <= 16'd0;
    mcu_data[2] <= 16'd0;
    mcu_data[3] <= 16'd0;
    mcu_data[4] <= 16'd0;
    mcu_data[5] <= 16'd0;
    mcu_data[6] <= 16'd0;
    mcu_data[7] <= 16'd0;
  end
// data input in addr
  else if( read_done ) begin
    mcu_data[emif_addr_reg1] <= fpga_read_reg;
  end
  else begin
    mcu_data[0] <= mcu_data[0];
    mcu_data[1] <= mcu_data[1];
    mcu_data[2] <= mcu_data[2];
    mcu_data[3] <= mcu_data[3];
    mcu_data[4] <= mcu_data[4];
    mcu_data[5] <= mcu_data[5];
    mcu_data[6] <= mcu_data[6];
    mcu_data[7] <= mcu_data[7];
  end
end
//////////////////////////////////////////////////////////////////////////////////
//                            encoder mode set module
//////////////////////////////////////////////////////////////////////////////////
always @(posedge clk or negedge rst_n) begin
  if(~rst_n) begin
    encoder_mode_reg <= 5'b00_000;
  end
// defualt 
  else begin
    encoder_mode_reg <= mcu_data[3];
  end
end

endmodule
