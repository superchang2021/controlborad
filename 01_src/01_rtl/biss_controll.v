` timescale 1ns/1ps
// 在接口板平台上测试bissc

module biss_controll(
// sys signals
  input    clk,      //系统clk J16
  input    clk_5M,
  input    rst_n,    //系统rst_n  P6
  input    key,          //按键  T7
//BiSS-C signals
  input    data_in,       //从机给主机输出的数据   A6
    output [25:0 ] data_out,
    output [7:0] crc_data,
    output [1:0] err_data,
    output clk_out        //主机给从机的时钟信号    A3
);

// parameter define
parameter  CRC_W  = 8'd8;              //CRC 校验位宽
parameter  DATA_W = 8'd26;             //数据位宽

wire [25:0] data;       //编码器角度数据
wire [7:0] crc_data;    //对应的校验位
wire [5:0] crc_c;       // 计算得到的CRC校验位
wire [1:0] err_data;
wire crc_en;

// assign define
assign de = 1'b1;
assign data_out = data;


/************************
      biss_control
************************/
biss_control_in U2_control(
// sys input
.clk         (clk),     //模块主时钟
.clk_5M      (clk_5M),      //10MHz基准时钟
.rst_n       (rst_n),    //复位信号
// input
.key         (key),          //按键信号
.data_in     (data_in),           //编码器输出信号
.clk_out     (clk_out),           //输出时钟信号
//output
.crc_en_o    (crc_en),
.crc_data    (crc_data),     //校验位
.err_data    (err_data),
.data_out    (data)          //获取的编码器数据
);

/************************
      biss_CRC
************************/
biss_crc6 U3_CRC(
.clk(clk),
.rst_n(rst_n),

.crc_en(crc_en),
.data_in({4'b0000,data,err_data}),
.crc_outt(crc_c)

);

endmodule
