
`timescale 1 ns / 10 ps
//////////////////////////////////////////////////////////////////////////////////
// Company: DMT
// Engineer: V
// Create Date: 2024/12/16 16:39
// Design Name: emif_setio
// Module Name: emif_setio
// Project Name: demo_1st_top
// Target Devices: Control Board V3
// Tool Versions: TD 5.6.2
// Description: using write_en&cas to set emif_data io in/out 
// Dependencies: demo_1st_top
// Revision:1.0
// Revision 1.01 - File Created
// Additional Comments: when mcu read,FPGA set the emif_data io to output
//////////////////////////////////////////////////////////////////////////////////
module emif_write(
// sys
  input           clk,             // 200MHz
  input           rst_n,           // reset
// input 
  input           write_en,        // emif we_logic
  input    [12:0] emif_addr,       // emif_addr
  input    [31:0] encoder_data,    // encoder_data input
// output
    output [15:0] fpga_write       // fpga data to mcu
);
// reg define
reg [15:0] fpag_write_reg;    // fpga data to mcu reg
// assign define
assign fpga_write = fpag_write_reg;
//////////////////////////////////////////////////////////////////////////////////
//                   data output by addr & encoder_mode module
//////////////////////////////////////////////////////////////////////////////////
//对应地址输出对应角度
always @(posedge clk or negedge rst_n) begin
  if(~rst_n) begin
    fpag_write_reg <= 16'd0;
  end
  else if( write_en ) begin
      if( emif_addr == 3'd0 )begin
        fpag_write_reg <= encoder_data[15:0];
      end
      else if( emif_addr == 3'd2 )begin
        fpag_write_reg <= encoder_data[25:16];
      end
      else if( emif_addr == 3'd4 )begin
        fpag_write_reg <= encoder_data[31:26];
      end
      else begin
        fpag_write_reg <= fpag_write_reg;
      end
  end
  else begin
    fpag_write_reg <= fpag_write_reg;
  end
end

endmodule
