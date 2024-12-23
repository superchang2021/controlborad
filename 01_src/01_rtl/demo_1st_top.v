
`timescale 1 ns / 10 ps
//////////////////////////////////////////////////////////////////////////////////
// Company: DMT INTELLIGENT EQUIPMENT TECHNOLOGY CO., LTD.
// Engineer: V
// Create Date: 2024/12/16 10:57
// Design Name: demo_1st_top
// Module Name: demo_1st_top
// Project Name: demo_1st_top
// Target Devices: Control Board V3
// Tool Versions: TD 5.6.2
// Description: first version demo for encoder data processing & data output to MCU
// Dependencies: TOP module
// Revision:1.0
// Revision 1.01 - File Created
// Additional Comments:FPGA chip EG4X20BG256,MCU communication protocol EMIF
//////////////////////////////////////////////////////////////////////////////////
module demo_1st_top(
// sys interface
  input          sys_clk_in,      // sys clock
  input          sys_rst_n_in,    // sys reset active low
// EMIF interface
  input          emif_clk_in,     // EMIF clock
  input          emif_cke_in,     // EMIF clock enable
  input          emif_ce_in,      // EMIF chip enable
  input          emif_we_in,      // EMIF write enable
  input          emif_cas_in,     // EMIF cas enable
  input          emif_ras_in,     // EMIF ras enable
  input          emif_dqm0_in,    // EMIF dqm0
  input          emif_dqm1_in,    // EMIF dqm1
  input [12:0]   emif_addr_in,    // EMIF address
  inout [15:0]   emif_data,       // EMIF data
// encoder interface
  input          sdo_a,           // sincos a in
  input          sdo_b,           // sincos b in
    output       sincos_clk,      // sincos clk
    output       sincos_cs_n,     // sincos cs_n
    output       a_out_able,      // a out able,high active
    output       b_out_able,      // b out able,high active
    output       z_out_able,      // z out able,high active
    inout        encoder_a,       // encoder a
    inout        encoder_b,       // encoder b
    inout        encoder_z,       // encoder z
// peripherals interface
    output [3:0] led_out          // led
);
// parameter define

// wire define
wire        clk_400M;
wire        clk_200M;
wire        clk_100M;
wire        clk_5M;
wire        locked;           // pll has locked fer clock/high active
wire        rst_n;            // global reset
wire        emif_clk;         // EMIF clock sync
wire        emif_cke;         // EMIF clock enable  sync
wire        emif_ce;          // EMIF chip enable sync
wire        emif_we;          // EMIF write enable  sync
wire        emif_cas;         // EMIF cas enable sync
wire        emif_ras;         // EMIF ras enable sync
wire        emif_we_logic;    // replace emif_we to dis read & write
wire        emif_idle;        // high when mcu idle
wire        flag_out;         // set data output flag
wire [12:0] emif_row_addr;    // row address
wire [12:0] emif_col_addr;    // column address
wire        fpga_read;        // fpga read enable
wire        fpga_write;       // fpga write enable
wire  [4:0] encoder_mode;
wire        read_done;        // fpga read done
wire [15:0] data_read;        // FPGA read data
wire [15:0] emif_data_out;
wire        data_a_out;
wire        data_b_out;
wire        data_z_out;
wire        flag_a_out;
wire        flag_b_out;
wire        flag_z_out;
wire [31:0] encoder_data;
// reg define
reg  [15:0] emif_data_reg;    // EMIF data register when output
reg         encoder_a_reg;    // encoder a reg when output
reg         encoder_b_reg;    // encoder b reg when output
reg         encoder_z_reg;    // encoder z reg when output
// assign define
assign emif_data = emif_data_reg;
assign encoder_a = encoder_a_reg;
assign encoder_b = encoder_b_reg;
assign encoder_z = encoder_z_reg;
assign a_out_able = flag_a_out;
assign b_out_able = flag_b_out;
assign z_out_able = flag_z_out;
//////////////////////////////////////////////////////////////////////////////////
//                          clock division module
//////////////////////////////////////////////////////////////////////////////////
my_pll u1_pll(
// clock in ports
.refclk        (sys_clk_in),       // input clock
// status and control signals
.reset         (~sys_rst_n_in),    // input reset
  .extlock     (locked),           // pll has locked fer clock /high active
// clock out ports
  .clk0_out    (clk_400M),         // output clock
  .clk1_out    (clk_200M),         // output clock
  .clk2_out    (clk_100M),         // output clock
  .clk3_out    (clk_5M)            // output clock
);
//////////////////////////////////////////////////////////////////////////////////
//                                rst_n BUFG
//////////////////////////////////////////////////////////////////////////////////
rst_BUFG u2_rst(
// input ports
.i(sys_rst_n_in),    // input reset
// output ports
  .o(rst_n)          // output reset,solve rst_n high fanout issue
);
//////////////////////////////////////////////////////////////////////////////////
//                      EMIF signal processing module
//////////////////////////////////////////////////////////////////////////////////
emif_signal_op u3_op(
// sys interface
.clk           (clk_200M),         // 200MHz sys clk
.rst_n         (rst_n),            // reset
// emif signal input
.clk_in        (emif_clk_in),      // EMIF clock input
.cke_in        (emif_cke_in),      // EMIF clock enable input
.ce_in         (emif_ce_in),       // EMIF chip enable input
.we_in         (emif_we_in),       // EMIF write enable input
.cas_in        (emif_cas_in),      // EMIF cas enable input
.ras_in        (emif_ras_in),      // EMIF ras enable input
// emif signal output
  .clk_out     (emif_clk),         // EMIF clock sync output 
  .cke_out     (emif_cke),         // EMIF clock enable  sync output
  .ce_out      (emif_ce),          // EMIF chip enable sync output 
  .we_out      (emif_we),          // EMIF write enable  sync output
  .cas_out     (emif_cas),         // EMIF cas enable sync output 
  .ras_out     (emif_ras),         // EMIF ras enable sync output 
// function signal
  .we_logic    (emif_we_logic),    // replace emif_we to dis read & write
  .mcu_idle    (emif_idle)         // high when mcu idle
);
//////////////////////////////////////////////////////////////////////////////////
//                      EMIF data set in/out module
//////////////////////////////////////////////////////////////////////////////////
emif_setio u4_setio(
// sys interface
.clk         (clk_400M),         // 400MHz sys clk
.rst_n       (rst_n),            // reset
// emif signal input
.cas_in      (emif_cas_in),      // EMIF cas enable input
.we_logic    (emif_we_logic),    // mcu read when high
// emif data output flag
  .setout    (flag_out)          // set data output flag
);
//////////////////////////////////////////////////////////////////////////////////
//                          EMIF control module
//////////////////////////////////////////////////////////////////////////////////
emif_control u5_control(
// sys interface
.clk             (clk_200M),          // 200MHz sys clk
.rst_n           (rst_n),             // reset
// emif input signal
.emif_clk        (emif_clk),          // EMIF clock sync output 
.emif_cke        (emif_cke),          // EMIF clock enable  sync output
.emif_ce         (emif_ce),           // EMIF chip enable sync output 
.wr_en           (emif_we_logic),     // replace emif_we to dis read & write
.rd_en           (~emif_we_logic),    // replace emif_we to dis read & write
.emif_cas        (emif_cas),          // EMIF cas enable sync output
.emif_ras        (emif_ras),          // EMIF ras enable sync output
.emif_dqm0       (emif_dqm0_in),      // EMIF dqm0
.emif_dqm1       (emif_dqm1_in),      // EMIF dqm1
.emif_addr       (emif_addr_in),      // EMIF address
// emif output signal
  .row_addr      (emif_row_addr),     // EMIF row address
  .col_addr      (emif_col_addr),     // EMIF column address
  .fpga_read     (fpga_read),         // FPGA read enable
  .fpga_write    (fpga_write)         // FPGA write enable
);
//////////////////////////////////////////////////////////////////////////////////
//                             EMIF fpga read module
//////////////////////////////////////////////////////////////////////////////////
emif_read u6_emif_read(
// sys signal
.clk               (clk_200M),         // 200MHz sys clk
.rst_n             (rst_n),            // reset
// input signal
.read_en           (~emif_we_logic),        // EMIF we logic
.emif_addr         (emif_addr_in),    // EMIF address
.data_in           (emif_data),     // EMIF data in
//output signal
  .encoder_mode    (encoder_mode),     // encoder mode
  .read_done       (read_done),        // read done reg
  .fpga_read       (data_read)         // FPGA read data
);
//////////////////////////////////////////////////////////////////////////////////
//                             EMIF fpga write module
//////////////////////////////////////////////////////////////////////////////////
emif_write u7_emif_write(
// sys signal
.clk               (clk_200M),         // 200MHz
.rst_n             (rst_n),            // reset
// input signal
.write_en          (emif_we_logic),         // FPGA w enable
.emif_addr         (emif_col_addr),    // emif_addr
.encoder_data      (encoder_data),     // encoder data
//output signal
  .fpga_write      (emif_data_out)     //FPGA write data to mcu
);
//////////////////////////////////////////////////////////////////////////////////
//                             encoder module
//////////////////////////////////////////////////////////////////////////////////
encoder_control u8_encoder(
// sys interface
.clk_200M        (clk_200M),      // 200MHz sys clk
.clk_100M        (clk_100M),      // 100MHz
.clk_5M          (clk_5M),        // 5MHz
.rst_n           (rst_n),         // reset
// signal input
.data_a_in       (encoder_a),     // encoder a data to fpga
.data_b_in       (encoder_b),     // encoder b data to fpga
.data_z_in       (encoder_z),     // encoder z data to fpga
.mode            (encoder_mode),  // encoder mode
.sdo_a           (sdo_a),         // sincos data to fpga
.sdo_b           (sdo_b),         // sincos data to fpga
// signal output
  .data_a_out    (data_a_out),    // fpga output to encoder a data
  .data_b_out    (data_b_out),    // fpga output to encoder b data
  .data_z_out    (data_z_out),    // fpga output to encoder z data
  .a_out         (flag_a_out),    // fpga output to encoder a able
  .b_out         (flag_b_out),    // fpga output to encoder b able
  .z_out         (flag_z_out),    // fpga output to encoder z able
  .sincos_clk    (sincos_clk),    // fpag output to sincos clk
  .sincos_cs_n   (sincos_cs_n),   // fpag output to sincos cs_n
  .data_out      (encoder_data)   // encoder data acquired
); 
//////////////////////////////////////////////////////////////////////////////////
//                              led module
//////////////////////////////////////////////////////////////////////////////////
led u9_led(
// sys input  
.clk      (clk_100M),    // 100MHz sys clk
.rst_n    (rst_n),       // reset
// output
  .led    (led_out)      // led output
);
//////////////////////////////////////////////////////////////////////////////////
//                          IO control module
//////////////////////////////////////////////////////////////////////////////////
always @(posedge clk_400M or negedge rst_n) begin
  if(~rst_n)begin
    emif_data_reg <= 16'd0;
  end
  else if(flag_out)begin
    emif_data_reg <= emif_data_out;
  end
  else begin
    emif_data_reg <= 16'hzzzz;
  end
end
always @(posedge clk_100M or negedge rst_n) begin
  if(~rst_n) begin
    encoder_a_reg <= 1'b0;
    encoder_b_reg <= 1'b0;
    encoder_z_reg <= 1'b0;
  end
  else if(flag_a_out) begin
    encoder_a_reg <= data_a_out;
  end
  else if(flag_b_out) begin
    encoder_b_reg <= data_b_out;
  end
  else if(flag_z_out) begin
    encoder_z_reg <= data_z_out;
  end
  else begin
    encoder_a_reg <= 1'bz;
    encoder_b_reg <= 1'bz;
    encoder_z_reg <= 1'bz;
  end
end

endmodule
