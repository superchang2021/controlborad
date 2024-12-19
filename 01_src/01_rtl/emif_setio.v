
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
// Description: using we_logic&cas to set emif_data io in/out 
// Dependencies: demo_1st_top
// Revision:1.0
// Revision 1.01 - File Created
// Additional Comments: when mcu read,FPGA set the emif_data io to output
//////////////////////////////////////////////////////////////////////////////////
module emif_setio(
// sys interface
  input    clk,          // 400MHz clk
  input    rst_n,        // sys reset
// emif signal input
  input    cas_in,       // EMIF cas enable input
  input    we_logic,     // mcu read when high
// emif data output flag
    output setout        // fpga output data to mcu,high active
);
// reg define
reg cas_reg0,cas_reg1;
reg flag_r_or_w;
reg [4:0] cnt_60ns;
reg setout_reg;
// assign define
assign setout = setout_reg;
//////////////////////////////////////////////////////////////////////////////////
//                         emif signal sync module
//////////////////////////////////////////////////////////////////////////////////
always @(posedge clk or negedge rst_n) begin
  if(~rst_n)begin
    cas_reg0 <= 1'b0;
    cas_reg1 <= 1'b0;
  end
  else begin
    cas_reg0 <= cas_in;
    cas_reg1 <= cas_reg0;
  end
end
//////////////////////////////////////////////////////////////////////////////////
//                        flag_r_or_w signal generate module
//////////////////////////////////////////////////////////////////////////////////
always @(posedge clk or negedge rst_n) begin
  if(~rst_n) begin
    flag_r_or_w <= 1'b0;
    cnt_60ns    <= 5'd25;
  end
// mcu read/write when cas negedge
  else if( {cas_reg0,cas_reg1} == 2'b01 ) begin
    cnt_60ns    <= 5'd1;
  end
// create 60ns op signal,ref the muc actual idle time
  else if( cnt_60ns <= 5'd23 ) begin
    flag_r_or_w <= 1'b1;
    cnt_60ns    <= cnt_60ns + 1'b1;
  end
  else begin
    flag_r_or_w <= 1'b0;
    cnt_60ns    <= 5'd25;
  end
end
//////////////////////////////////////////////////////////////////////////////////
//                         setout signal generate module
//////////////////////////////////////////////////////////////////////////////////
always @(posedge clk or negedge rst_n) begin
  if(~rst_n) begin
    setout_reg <= 1'b0;
  end
// mcu read/write && mcu read,set io output
  else if( flag_r_or_w & we_logic ) begin
    setout_reg <= 1'b1;
  end
  else begin
    setout_reg <= 1'b0;
  end
end

endmodule
