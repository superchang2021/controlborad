
`timescale 1 ns / 10 ps
/************************************************************\
 **     Copyright (c) 2012-2023 Anlogic Inc.
 **  All Right Reserved.\
\************************************************************/
/************************************************************\
 ** Log	:	This file is generated by Anlogic IP Generator.
 ** File	:	D:/Chang/files/code/anlogic_verilog/Interface/demo_1st/01_src/03_ip/my_pll.v
 ** Date	:	2024 12 16
 ** TD version	:	5.6.71036
\************************************************************/

///////////////////////////////////////////////////////////////////////////////
//	Input frequency:             50.000MHz
//	Clock multiplication factor: 8
//	Clock division factor:       1
//	Clock information:
//		Clock name	| Frequency 	| Phase shift
//		C0        	| 400.000000MHZ	| 0  DEG     
//		C1        	| 200.000000MHZ	| 0  DEG     
//		C2        	| 100.000000MHZ	| 0  DEG     
//		C3        	| 5.000000  MHZ	| 0  DEG     
///////////////////////////////////////////////////////////////////////////////
module my_pll (
  refclk,
  reset,
  extlock,
  clk0_out,
  clk1_out,
  clk2_out,
  clk3_out 
);

  input refclk;
  input reset;
  output extlock;
  output clk0_out;
  output clk1_out;
  output clk2_out;
  output clk3_out;

  wire clk0_buf;

  EG_LOGIC_BUFG bufg_feedback (
    .i(clk0_buf),
    .o(clk0_out) 
  );

  EG_PHY_PLL #(
    .DPHASE_SOURCE("DISABLE"),
    .DYNCFG("DISABLE"),
    .FIN("50.000"),
    .FEEDBK_MODE("NORMAL"),
    .FEEDBK_PATH("CLKC0_EXT"),
    .STDBY_ENABLE("DISABLE"),
    .PLLRST_ENA("ENABLE"),
    .SYNC_ENABLE("DISABLE"),
    .GMC_GAIN(4),
    .ICP_CURRENT(13),
    .KVCO(4),
    .LPF_CAPACITOR(1),
    .LPF_RESISTOR(4),
    .REFCLK_DIV(1),
    .FBCLK_DIV(8),
    .CLKC0_ENABLE("ENABLE"),
    .CLKC0_DIV(1),
    .CLKC0_CPHASE(1),
    .CLKC0_FPHASE(0),
    .CLKC1_ENABLE("ENABLE"),
    .CLKC1_DIV(2),
    .CLKC1_CPHASE(1),
    .CLKC1_FPHASE(0),
    .CLKC2_ENABLE("ENABLE"),
    .CLKC2_DIV(4),
    .CLKC2_CPHASE(3),
    .CLKC2_FPHASE(0),
    .CLKC3_ENABLE("ENABLE"),
    .CLKC3_DIV(80),
    .CLKC3_CPHASE(79),
    .CLKC3_FPHASE(0) 
  ) pll_inst (
    .refclk(refclk),
    .reset(reset),
    .stdby(1'b0),
    .extlock(extlock),
    .load_reg(1'b0),
    .psclk(1'b0),
    .psdown(1'b0),
    .psstep(1'b0),
    .psclksel(3'b000),
    .psdone(open),
    .dclk(1'b0),
    .dcs(1'b0),
    .dwe(1'b0),
    .di(8'b00000000),
    .daddr(6'b000000),
    .do({open, open, open, open, open, open, open, open}),
    .fbclk(clk0_out),
    .clkc({open, clk3_out, clk2_out, clk1_out, clk0_buf}) 
  );

endmodule
