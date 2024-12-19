
`timescale 1 ns / 10 ps
//////////////////////////////////////////////////////////////////////////////////
// Company: DMT
// Engineer: V
// Create Date: 2024/12/17 16:01
// Design Name: encoder_control
// Module Name: encoder_control
// Project Name: demo_1st_top
// Target Devices: Control Board V3
// Tool Versions: TD 5.6.2
// Description: encoder data decoding top module
// Dependencies: demo_1st_top
// Revision:1.0
// Revision 1.01 - File Created
// Additional Comments:
//////////////////////////////////////////////////////////////////////////////////
module endat_contol_sample(
  input    clk,               // 200MHz主时钟
  input    rst_n,             // 复位信号
  input    key,               // 按键信号，用来启动读数
  input    data_in,           //编码器输入进来的数据
    output flag_out,          // MI状态时拉高
    output data_mi,
    output clk_out,           // 把10MHz时钟输出给编码器
    output [20:0] data_angle/*synthesis keep*/    // FPGA捕获到的数据
);
// parameter define  
parameter IDLE = 5'b00001;
parameter S1   = 5'b00010;
parameter MI   = 5'b00100;
parameter S2   = 5'b01000;
parameter DATA = 5'b10000;    // 8个状态独热码定义  

parameter CNT_MAX = 32'd20000;    //20ms寄存器，用来按键消除抖动(不仿真时，将值改为上面的)
// parameter CNT_PLL = 32'd499;      //在200MHz情况下需要计数CNT_PLL次达到200kHz
parameter CNT_PLL = 32'd49;    // 200MHz情况下需要计数CNT_PLL次达到2MHz

// wire define
wire IDLE2S1_start;
wire S12MI_start;
wire MI2S2_start;
wire S22DATA_start;
wire DATA2IDLE_start;    //状态转移条件

wire        error/*synthesis keep*/;
wire [12:0] position/*synthesis keep*/;
wire  [4:0] crc/*synthesis keep*/;

wire        clk_out_rev;         //输出给编码器时钟的反向，用于锁存数据（100时钟锁存太多次了）

// reg define
reg [5:0] mi_id;

reg [4:0] state_c;    //当前状态寄存
reg [4:0] state_n;    //下个状态寄存

reg [31:0] cnt_clk;    //用于生成200khz时钟
reg clk_200k;

reg key_reg0;         //按键信号锁存 寄存捕获边沿
reg key_reg1;         //按键信号锁存 寄存捕获边沿
reg clk_10M_reg0;     //200kHz时钟锁存 寄存捕获边沿
reg clk_10M_reg1;     //200kHz时钟锁存 寄存捕获边沿
reg angle_request;    //记录按键有没有按下
reg request;          //当按键按下后，就一直拉高，用来控制通讯开始
reg flag_out_reg;
reg data_mi_reg;

reg [31:0] cnt_timer_10M;    //按键消除抖动对10MHz时钟进行计数

reg pose_clk_200kHz;    //按键按下后的输出时钟的第一个上升沿


reg        clk_out_reg;         //输出给编码器的时钟
reg        clk_out_reg0;        //输出给编码器的时钟 寄存捕获边沿
reg        clk_out_reg1;        //输出给编码器的时钟 寄存捕获边沿
reg        clk_out_reg_pose;    //输出时钟的上升沿
reg [31:0] cnt_pose;            //输出时钟上升沿计数
reg [31:0] cnt_pose_down;       //输出时钟下降沿计数

reg        data_in_reg0;     //编码器输入信号锁存 寄存捕获边沿
reg        data_in_reg1;     //编码器输入信号锁存 寄存捕获边沿
reg        data_in_pose;     //编码器输入信号的上升沿
reg [31:0] cnt_data_pose;    //编码器输入信号上升沿计数

reg [20:0] angle/*synthesis keep*/;       //编码器输入的角度信息
reg  [4:0] data_crc;    //编码器输入的校验位


reg [15:0] DATA_cntclk;    //在DATA状态，对时钟上升沿进行计数
reg [15:0] DATA_cntclkdown;//在DATA状态，对时钟下降沿进行计数
reg [31:0] S2_cntclk;     //在S2状态，对时钟下降沿进行计数

reg flag_S1;     //状态转移条件
reg flag_MI;     //状态转移条件
reg flag_S2;     //状态转移条件
reg flag_DATA;    //状态转移条件
reg flag_IDLE;    //状态转移条件

// assign define
assign data_angle = angle;          //输出给其他模块的角度信息（包含S、F、S、C）
assign clk_out  = clk_out_reg;    //输出给编码器的时钟信号
assign clk_out_rev = ~clk_out_reg1;    //进行取反，方便计数
assign flag_out = flag_out_reg;
assign data_mi = data_mi_reg;

assign error = angle[1];
assign position = angle[14:2];
assign crc = angle[19:15];

// mi id  控制模块
always @(posedge clk or negedge rst_n) begin
  if(~rst_n) begin
    mi_id <= 6'd0;
  end
  else begin
    mi_id <= 6'b000111;
  end
end



//******************************************************
//**   200KHz 手动时钟生成，pll分频不出来
//******************************************************
always @(posedge clk or negedge rst_n) begin
  if(~rst_n) begin
    clk_200k <= 1'b1;
    cnt_clk <= 32'd0;
  end
  else if(cnt_clk == CNT_PLL) begin
    clk_200k <= ~clk_200k;
    cnt_clk <= 32'd0;
  end
  else begin
    clk_200k <= clk_200k;
    cnt_clk <= cnt_clk + 1'b1;
  end
end

//******************************************************
//**   控制角度读取，第一次读取为按下按键，之后自动读取
//******************************************************
// 寄存按键值
always @(posedge clk_200k or negedge rst_n) begin
  if(~rst_n) begin
    key_reg0 <= 1'b0;
    key_reg1 <= 1'b0;
  end
  else begin
    key_reg0 <= key;
    key_reg1 <= key_reg0;
  end
end
// 按键消除抖动
always @(posedge clk_200k or negedge rst_n) begin
  if(~rst_n) begin
    cnt_timer_10M <= 32'd0;
  end
  else begin
    if(key_reg0 != key_reg1) begin
      cnt_timer_10M <= CNT_MAX;
    end
    else begin
      if(cnt_timer_10M > 32'd0) begin
        cnt_timer_10M <= cnt_timer_10M -1'b1;
      end
      else begin
        cnt_timer_10M <= 1'b0;
      end
    end
  end
end
// 按键消除抖动后将request信号拉高
always @(posedge clk or negedge rst_n) begin
  if(~rst_n) begin
    angle_request <= 1'b0;
  end
  else if(cnt_timer_10M == 1'b1) begin
    angle_request <= 1'b1;
  end
  else begin
    angle_request <= 1'b0;
  end
end

//******************************************************
//**     将200kHz时钟同步给出到编码器
//******************************************************

// 捕获clk_200kHz的上升沿
always @(posedge clk or negedge rst_n) begin
  if(~rst_n) begin
    clk_10M_reg0 <= 1'b1;
    clk_10M_reg1 <= 1'b1;
  end
  else begin
    clk_10M_reg0 <= clk_200k;
    clk_10M_reg1 <= clk_10M_reg0;
  end
end

// 当按键按下，angle_request=1，将request拉高,当状态转移到IDLE时，拉低
always @(posedge clk or negedge rst_n) begin
  if(~rst_n) begin
    request <= 1'b0;
  end
  else if(angle_request) begin
    request <= 1'b1;
  end
  else if(flag_IDLE) begin
    request <= 1'b0;
  end
  else begin
    request <= request;
  end
end

// 当request为高时，在第一个clk_200kHz上升沿就一直拉高pose_clk_200kHz
always @(posedge clk or negedge rst_n) begin
  if(~rst_n) begin
    pose_clk_200kHz <= 1'b0;
  end
  else if({request,clk_10M_reg0,clk_10M_reg1} == 3'b110) begin
    pose_clk_200kHz <= 1'b1;
  end
  else if(~request) begin    //当request = 0 时，拉低该信号
    pose_clk_200kHz <= 1'b0;
  end
  else begin
    pose_clk_200kHz <= pose_clk_200kHz;
  end
end

// 当request拉高的时候，将200kHz时钟同步出去
always @(posedge clk or negedge rst_n) begin
  if(~rst_n) begin
    clk_out_reg <= 1'b1;
  end
  else if(flag_IDLE) begin    //STP 状态将输出时钟拉低
    clk_out_reg <= 1'b1;
  end
  else if(pose_clk_200kHz) begin
    clk_out_reg <= clk_200k;
  end
  else begin
    clk_out_reg <= clk_out_reg;
  end
end

//**********************************************
// 状态信号生成
//**********************************************

// 寄存输出时钟
always @(posedge clk or negedge rst_n) begin
  if(~rst_n) begin
    clk_out_reg0 <= 1'b1;
    clk_out_reg1 <= 1'b1;
  end
  else begin
    clk_out_reg0 <= clk_out_reg;
    clk_out_reg1 <= clk_out_reg0;
  end
end

// data_in 锁存
always @(posedge clk or negedge rst_n) begin
  if(~rst_n) begin
    data_in_reg0 <= 1'b1;
    data_in_reg1 <= 1'b1;
  end
  else begin
    data_in_reg0 <= data_in;
    data_in_reg1 <= data_in_reg0;
  end
end

// 输出时钟上升沿捕获/下降沿捕获
always @(posedge clk or negedge rst_n) begin
  if(~rst_n) begin
    clk_out_reg_pose <= 1'b0;
    cnt_pose <= 32'd0;
    cnt_pose_down <= 32'd0;
  end
  else if(flag_IDLE) begin
    clk_out_reg_pose <= 1'b0;
    cnt_pose <= 32'd0;
    cnt_pose_down <= 32'd0;
  end
  else if({clk_out_reg0,clk_out_reg1} == 2'b10) begin
    clk_out_reg_pose <= 1'b1;
    cnt_pose <= cnt_pose + 1'b1;
  end
  else if({clk_out_reg0,clk_out_reg1} == 2'b01) begin
    cnt_pose_down <= cnt_pose_down + 1'b1;
  end
  else begin
    clk_out_reg_pose <= 1'b0;
    cnt_pose <= cnt_pose;
    cnt_pose_down <= cnt_pose_down;
  end
end

// data_in 上升沿捕获
always @(posedge clk or negedge rst_n) begin
  if(~rst_n) begin
    data_in_pose <= 1'b0;
    cnt_data_pose <= 32'd0;
  end
  else if(flag_IDLE) begin
    cnt_data_pose <= 32'd0;
    data_in_pose <= 1'b0;
  end
  else if(flag_S2) begin
    cnt_data_pose <= 32'd0;
    data_in_pose <= 1'b0;
  end
  else if({data_in_reg0,data_in_reg1} == 2'b10) begin
    data_in_pose <= 1'b1;
    cnt_data_pose <= cnt_data_pose + 1'b1;
  end
  else begin
    data_in_pose <= 1'b0;
    cnt_data_pose <= cnt_data_pose;
  end
end

// S1 输出时钟的第一个下降沿标志着状态的开始
// MI 输出时钟的第三个下降沿标志着状态的开始
// S2 输出时钟的第九个下降沿标志着状态的开始
always @(posedge clk or negedge rst_n) begin
  if(~rst_n) begin
    flag_S1 <= 1'b0;
    flag_MI <= 1'b0;
    flag_S2 <= 1'b0;
  end
  else if(({clk_out_reg0,clk_out_reg1} == 2'b01) && (cnt_pose_down == 8'd0)) begin
    flag_S1 <= 1'b1;
  end
  else if(({clk_out_reg0,clk_out_reg1} == 2'b01) && (cnt_pose_down == 8'd2)) begin
    flag_MI <= 1'b1;
  end
  else if(({clk_out_reg0,clk_out_reg1} == 2'b01) && (cnt_pose_down == 8'd8)) begin
    flag_S2 <= 1'b1;
  end
  else begin
    flag_S1 <= 1'b0;
    flag_MI <= 1'b0;
    flag_S2 <= 1'b0;
  end
end

// DATA 再S2状态下，第5个（可以调整）下降沿后，DATA线的上升沿标志开始
// 调整为4
always @(posedge clk or negedge rst_n) begin
  if(~rst_n) begin
    flag_DATA <= 1'b0;
  end
  else if(S2_cntclk >= 32'd4 && data_in_pose && (cnt_data_pose == 1'b1)) begin
    flag_DATA <= 1'b1;
  end
  else begin
    flag_DATA <= 1'b0;
  end
end

// IDLE 再DATA状态下，经过1+1+13+5个周期后，进入IDLE状态(清零一些寄存器)
always @(posedge clk or negedge rst_n) begin
  if(~rst_n) begin
    flag_IDLE <= 1'b0;
  end
  else if(DATA_cntclkdown == 16'd22 && state_c == DATA) begin
    flag_IDLE <= 1'b1;
  end
  else begin
    flag_IDLE <= 1'b0;
  end
end



//******************************************************
// 同步时序always块，格式化描述次态迁移到现态寄存器
//******************************************************
always @(posedge clk or negedge rst_n) begin
  if(~rst_n) begin
    state_c <= IDLE;
  end
  else begin
    state_c <= state_n;
  end
end
//**************************************
// 组合逻辑always块，描述状态转移条件
//**************************************
always @(*) begin
  case(state_c)
    IDLE:begin
      if(IDLE2S1_start) begin
        state_n <= S1;
      end
      else begin
        state_n <= state_c;
      end
    end
    S1:begin
      if(S12MI_start) begin
        state_n <= MI;
      end
      else begin
        state_n <= state_c;
      end
    end
    MI:begin
      if(MI2S2_start) begin
        state_n <= S2;
      end
      else begin
        state_n <= state_c;
      end
    end
    S2:begin
      if(S22DATA_start) begin
        state_n <= DATA;
      end
      else begin
        state_n <= state_c;
      end
    end
    DATA:begin
      if(DATA2IDLE_start) begin
        state_n <= IDLE;
      end
      else begin
        state_n <= state_c;
      end
    end
    default:begin
      state_n <= IDLE;
    end
  endcase
end
//**************************************
//          定义状态转移条件
//**************************************
assign IDLE2S1_start    = (state_c == IDLE) && flag_S1;
assign S12MI_start      = (state_c == S1)   && flag_MI;
assign MI2S2_start      = (state_c == MI)   && flag_S2;
assign S22DATA_start    = (state_c == S2)   && flag_DATA;
assign DATA2IDLE_start  = (state_c == DATA) && flag_IDLE;

//**************************************
//     设计输出，一个always块一个信号
//**************************************

// S2 状态对时钟进行计数
always @(posedge clk or negedge rst_n) begin
  if(~rst_n) begin
    S2_cntclk <= 32'd0;
  end
  else if(flag_IDLE) begin
    S2_cntclk <= 32'd0;
  end
  else if (state_c == S2 && clk_out_reg_pose)begin
    S2_cntclk <= S2_cntclk + 1'b1;
  end
  else begin
    S2_cntclk <= S2_cntclk;
  end
end

// DATA 状态对时钟进行计数
always @(posedge clk or negedge rst_n) begin
  if(~rst_n) begin
    DATA_cntclk <= 16'd0;
    DATA_cntclkdown <= 16'd0;
  end
  else if(flag_IDLE) begin
    DATA_cntclk <= 16'd0;
    DATA_cntclkdown <= 16'd0;
  end
  else if (state_c == DATA && clk_out_reg_pose)begin
    DATA_cntclk <= DATA_cntclk + 1'b1;
  end
  else if(state_c == DATA && ({clk_out_reg0,clk_out_reg1} == 2'b01)) begin
    DATA_cntclkdown <= DATA_cntclkdown + 1'b1;
  end
  else begin
    DATA_cntclk <= DATA_cntclk;
    DATA_cntclkdown <= DATA_cntclkdown;
  end
end

// MI状态输出6bit命令
always @(posedge clk or negedge rst_n) begin
  if(~rst_n) begin
    data_mi_reg <= 1'b1;
  end
  else if(state_c == MI)begin
    case(cnt_pose_down)
      3:begin
        data_mi_reg <= mi_id[5];
      end
      4:begin
        data_mi_reg <= mi_id[4];
      end
      5:begin
        data_mi_reg <= mi_id[3];
      end
      6:begin
        data_mi_reg <= mi_id[2];
      end
      7:begin
        data_mi_reg <= mi_id[1];
      end
      8:begin
        data_mi_reg <= mi_id[0];
      end
      default:begin
        data_mi_reg <= 1'b1;
      end
    endcase
  end
  else begin
    data_mi_reg <= 1'b1;
  end
end

// MI状态拉高flag信号
always @(posedge clk or negedge rst_n) begin
  if(~rst_n) begin
    flag_out_reg <= 1'b0;
  end
  else if(state_c == MI) begin
    flag_out_reg <= 1'b1;
  end
  else begin
    flag_out_reg <= 1'b0;
  end
end

// DATA状态通过输出时钟个数对应寄存角度值和状态转移信号；
always @(posedge clk_out_rev or negedge rst_n) begin
  if(~rst_n) begin
    angle <= 21'd0;
  end
  else if (state_c == DATA) begin
    case(DATA_cntclkdown)
      1:begin
        angle[0] <= data_in_reg1;  // 开始标示
      end
      2:begin
        angle[1] <= data_in_reg1;  // 错误信号1
      end
      3:begin
        angle[2] <= data_in_reg1;  // 错误信号2
      end
      4:begin
        angle[3] <= data_in_reg1;  // 数据最低位
      end
      5:begin
        angle[4] <= data_in_reg1;
      end
      6:begin
        angle[5] <= data_in_reg1;
      end
      7:begin
        angle[6] <= data_in_reg1;
      end
      8:begin
        angle[7] <= data_in_reg1;
      end
      9:begin
        angle[8] <= data_in_reg1;
      end
      10:begin
        angle[9] <= data_in_reg1;
      end
      11:begin
        angle[10] <= data_in_reg1;
      end
      12:begin
        angle[11] <= data_in_reg1;
      end
      13:begin
        angle[12] <= data_in_reg1;
      end
      14:begin
        angle[13] <= data_in_reg1;
      end
      15:begin
        angle[14] <= data_in_reg1;
      end
      16:begin
        angle[15] <= data_in_reg1;  // 数据最高位
      end
      17:begin
        angle[16] <= data_in_reg1;
      end
      18:begin
        angle[17] <= data_in_reg1;
      end
      19:begin
        angle[18] <= data_in_reg1;
      end
      20:begin
        angle[19] <= data_in_reg1;
      end
      21:begin
        angle[20] <= data_in_reg1;
      end
      default:begin
        angle <= angle;
      end
    endcase
  end
  else begin
    angle <= angle;
  end
end

endmodule
