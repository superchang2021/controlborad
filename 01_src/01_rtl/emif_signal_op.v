
`timescale 1 ns / 10 ps
//////////////////////////////////////////////////////////////////////////////////
// Company: DMT
// Engineer: V
// Create Date: 2024/12/16 14:36
// Design Name: emif_signal_op
// Module Name: emif_signal_op
// Project Name: demo_1st_top
// Target Devices: Control Board V3
// Tool Versions: TD 5.6.2
// Description: sync emif input signal & output functional signal
// Dependencies: demo_1st_top
// Revision:1.0
// Revision 1.01 - File Created
// Additional Comments: clk & cke & idle were not used
//////////////////////////////////////////////////////////////////////////////////
module emif_signal_op(
// sys interface
  input clk,            // 200MHz sys clk
  input rst_n,          // reset
// emif signal input
  input clk_in,         // EMIF clock input
  input cke_in,         // EMIF clock enable input
  input ce_in,          // EMIF chip enable input
  input we_in,          // EMIF write enable input
  input cas_in,         // EMIF cas enable input
  input ras_in,         // EMIF ras enable input
// emif signal sync output
    output clk_out,     // EMIF clock sync output 
    output cke_out,     // EMIF clock enable  sync output 
    output ce_out,      // EMIF chip enable sync output 
    output we_out,      // EMIF write enable  sync output 
    output cas_out,     // EMIF cas enable sync output 
    output ras_out,     // EMIF ras enable sync output 
// function signal
    output we_logic,    // replace emif_we to dis read & write
    output mcu_idle     // high when mcu idle
);
// reg define
reg        clk_in1,clk_in2;    // temporary variable storage
reg        cke_in1,cke_in2;    // temporary variable storage
reg        ce_in1,ce_in2;      // temporary variable storage
reg        we_in1,we_in2;      // temporary variable storage
reg        cas_in1,cas_in2;    // temporary variable storage
reg        ras_in1,ras_in2;    // temporary variable storage
reg        mcu_idle_reg;       // temporary variable storage
reg        we_logic_reg;       // temporary variable storage
reg  [3:0] we_down_cnt;        // we signal down counter
reg  [5:0] idle_cnt;           // idle signal counter
// assign define
assign clk_out  = clk_in2;
assign cke_out  = cke_in2;
assign ce_out   = ce_in2;
assign we_out   = we_in2;
assign cas_out  = cas_in2;
assign ras_out  = ras_in2;
assign we_logic = we_logic_reg;
assign mcu_idle = mcu_idle_reg; 
//////////////////////////////////////////////////////////////////////////////////
//                         emif signal sync module
//////////////////////////////////////////////////////////////////////////////////
always @(posedge clk or negedge rst_n)begin
  if(~rst_n) begin
    clk_in1 <= 1'b1;
    clk_in2 <= 1'b1;
    cke_in1 <= 1'b1;
    cke_in2 <= 1'b1;
    ce_in1  <= 1'b1;
    ce_in2  <= 1'b1;
    we_in1  <= 1'b1;
    we_in2  <= 1'b1;
    cas_in1 <= 1'b1;
    cas_in2 <= 1'b1;
    ras_in1 <= 1'b1;
    ras_in2 <= 1'b1;
  end
// using 2 reg to sync emif signal
  else begin
    clk_in1 <= clk_in ;
    clk_in2 <= clk_in1;
    cke_in1 <= cke_in ;
    cke_in2 <= cke_in1;
    ce_in1  <= ce_in  ;
    ce_in2  <= ce_in1 ;
    we_in1  <= we_in  ;
    we_in2  <= we_in1 ;
    cas_in1 <= cas_in ;
    cas_in2 <= cas_in1;
    ras_in1 <= ras_in ;
    ras_in2 <= ras_in1;
  end
end
//////////////////////////////////////////////////////////////////////////////////
//                      we_logic signal generate module
//////////////////////////////////////////////////////////////////////////////////
always @(posedge clk or negedge rst_n) begin
  if(~rst_n) begin
    we_logic_reg <= 1'b1 ;
    we_down_cnt  <= 4'd10;
  end
// using we & cas are both at low level
  else if( {we_in,cas_in} == 2'b00 ) begin
    we_down_cnt  <= 4'd1;
  end
// create 6 clk we_logic low active signal
  else if( we_down_cnt <= 8'd7 ) begin
    we_logic_reg <= 1'b0;
    we_down_cnt  <= we_down_cnt + 1'b1;
  end
  else begin
    we_logic_reg <= 1'b1 ;
    we_down_cnt  <= 4'd10;
  end
end
//////////////////////////////////////////////////////////////////////////////////
//                      mcu_idle signal generate module
//////////////////////////////////////////////////////////////////////////////////
always @(posedge clk or negedge rst_n) begin
  if(~rst_n) begin
    mcu_idle_reg <= 1'b1;
    idle_cnt     <= 6'd62;
  end
// using we low state to judge idle
  else if( ~we_in ) begin
    idle_cnt     <= 6'd1;
  end
// create 300ns idle signal,ref the muc actual idle time
  else if( idle_cnt <= 6'd59 ) begin
    mcu_idle_reg <= 1'b0;
    idle_cnt     <= idle_cnt + 1'b1;
  end
  else begin
    mcu_idle_reg <= 1'b1 ;
    idle_cnt     <= 6'd62;
  end
end

endmodule
