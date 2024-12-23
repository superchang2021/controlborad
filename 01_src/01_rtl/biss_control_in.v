
module biss_control_in(
  input    clk,               // 200MHz主时钟
  input    clk_5M,           // 10MHz 时钟
  input    rst_n,             // 复位信号
  input    data_in,           // 编码器输入进来的数据
  input    key,               // 按键信号，用来启动读数
    output clk_out,           // 把10MHz时钟输出给编码器
    output crc_en_o,
    output [1:0] err_data,
    output [5:0] crc_data/*synthesis keep*/,    // 校验位
    output [25:0] data_out/*synthesis keep*/
);
// parameter define  
parameter IDLE = 4'b0001;
parameter ACK  = 4'b0010;
parameter STR  = 4'b0100;
parameter STP  = 4'b1000;       // 4个状态独热码定义

parameter CNT_MAX = 32'd20_0000;    //20ms寄存器，用来按键消除抖动(不仿真时，将值改为上面的)

// wire define
wire IDLE2ACK_start;
wire ACK2STR_start;
wire STR2STP_start;
wire STP2IDLE_start;    //状态转移条件

wire        clk_out_rev;         //输出给编码器时钟的反向，用于锁存数据（100时钟锁存太多次了）

// reg define
reg [3:0] state_c;    //当前状态寄存
reg [3:0] state_n;    //下个状态寄存

reg key_reg0;         //按键信号锁存 寄存捕获边沿
reg key_reg1;         //按键信号锁存 寄存捕获边沿
reg clk_5M_reg0;     //5MHz时钟锁存 寄存捕获边沿
reg clk_5M_reg1;     //5MHz时钟锁存 寄存捕获边沿
reg angle_request;    //记录按键有没有按下
reg request;          //当按键按下后，就一直拉高，用来控制通讯开始

reg [31:0] cnt_timer_10M;    //按键消除抖动对10MHz时钟进行计数

reg pose_clk_5MHz;    //按键按下后的输出时钟的第一个上升沿

reg        clk_out_reg;         //输出给编码器的时钟
reg        clk_out_reg0;        //输出给编码器的时钟 寄存捕获边沿
reg        clk_out_reg1;        //输出给编码器的时钟 寄存捕获边沿

reg        data_in_reg0;     //编码器输入信号锁存 寄存捕获边沿
reg        data_in_reg1;     //编码器输入信号锁存 寄存捕获边沿

reg [25:0] angle;       //编码器输入的角度信息
reg  [1:0] error;       //报警位
reg  [5:0] data_crc;    //编码器输入的校验位
reg        crc_en;
reg read_done;

reg [15:0] STR_cntclk;     //在STR状态，对时钟上升沿进行计数
reg [15:0] STR_cntclkdown; //在STR状态，对时钟下降沿进行计数

reg flag_ACK;     //状态转移条件
reg flag_STR;     //状态转移条件
reg flag_STP;     //状态转移条件
reg flag_IDLE;    //状态转移条件

// assign define
assign data_out = angle;          //赋值输出
assign clk_out  = clk_out_reg;    //赋值输出
assign crc_data = data_crc;       //赋值输出
assign clk_out_rev = ~clk_out_reg1;
assign crc_en_o = crc_en;
assign err_data = error;

//******************************************************
//**   控制角度读取，第一次读取为按下按键，之后自动读取
//******************************************************
// 寄存按键值
always @(posedge clk_5M or negedge rst_n) begin
  if(~rst_n) begin
    key_reg0 <= 1'b1;
    key_reg1 <= 1'b1;
  end
  else begin
    key_reg0 <= key;
    key_reg1 <= key_reg0;
  end
end
// 按键消除抖动
always @(posedge clk_5M or negedge rst_n) begin
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
always @(posedge clk_5M or negedge rst_n) begin
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
//**     将5MHz时钟同步给出到编码器
//******************************************************

// 捕获clk_5MHz的上升沿
always @(posedge clk or negedge rst_n) begin
  if(~rst_n) begin
    clk_5M_reg0 <= 1'b1;
    clk_5M_reg1 <= 1'b1;
  end
  else begin
    clk_5M_reg0 <= clk_5M;
    clk_5M_reg1 <= clk_5M_reg0;
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

// 当request为高时，在第一个clk_5MHz上升沿就一直拉高pose_clk_5MHz
always @(posedge clk or negedge rst_n) begin
  if(~rst_n) begin
    pose_clk_5MHz <= 1'b0;
  end
  else if({request,clk_5M_reg0,clk_5M_reg1} == 3'b110) begin
    pose_clk_5MHz <= 1'b1;
  end
  else if(~request) begin    //当request = 0 时，拉低该信号
    pose_clk_5MHz <= 1'b0;
  end
  else begin
    pose_clk_5MHz <= pose_clk_5MHz;
  end
end

// 当request拉高的时候，将10MHz时钟同步出去
always @(posedge clk or negedge rst_n) begin
  if(~rst_n) begin
    clk_out_reg <= 1'b1;
  end
  else if(state_c == STP) begin    //STP 状态将输出时钟拉低
    clk_out_reg <= 1'b1;
  end
  else if(pose_clk_5MHz) begin
    clk_out_reg <= clk_5M;
  end
  else begin
    clk_out_reg <= 1'b1;
  end
end

//**********************************************
// 状态信号生成
//**********************************************

// 输出时钟 寄存
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

// 输入信号 寄存
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


//******************************************************
//   状态标志信号 flag_XXXX 生成模块
//******************************************************

// ACK IDLE状态下第一个data_in的下降沿看做是ACK状态的开始

always @(posedge clk or negedge rst_n) begin
  if(~rst_n) begin
    flag_ACK <= 1'b0;
  end
  else if(({data_in_reg0,data_in_reg1} == 2'b01) && state_c == IDLE) begin
    flag_ACK <= 1'b1;
  end
  else begin
    flag_ACK <= 1'b0;
  end
end

//STR ACK状态下第一个data_in的上升沿看做是STR状态的开始

always @(posedge clk or negedge rst_n) begin
  if(~rst_n) begin
    flag_STR <= 1'b0;
  end
  else if(({data_in_reg0,data_in_reg1} == 2'b10) && state_c == ACK) begin
    flag_STR <= 1'b1;
  end
  else begin
    flag_STR <= 1'b0;
  end
end

// STP STR状态下，第时钟的第37个上升沿为标志信号

always @(posedge clk or negedge rst_n) begin
  if(~rst_n) begin
    flag_STP <= 1'b0;
  end
  else if(STR_cntclk == 16'd37 && state_c == STR) begin
    flag_STP <= 1'b1;
  end
  else begin
    flag_STP <= 1'b0;
  end
end

// IDLE STP状态下，第一个数据上升沿可以看做IDLE状态的开始，此时清零某些寄存器

always @(posedge clk or negedge rst_n) begin
  if(~rst_n) begin
    flag_IDLE <= 1'b0;
  end
  else if(state_c == STP && {data_in_reg0,data_in_reg1} == 2'b10) begin
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
      if(IDLE2ACK_start) begin
        state_n <= ACK;
      end
      else begin
        state_n <= state_c;
      end
    end
    ACK:begin
      if(ACK2STR_start) begin
        state_n <= STR;
      end
      else begin
        state_n <= state_c;
      end
    end
    STR:begin
      if(STR2STP_start) begin
        state_n <= STP;
      end
      else begin
        state_n <= state_c;
      end
    end
    STP:begin
      if(STP2IDLE_start) begin
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
assign IDLE2ACK_start  = (state_c == IDLE) && flag_ACK;
assign ACK2STR_start   = (state_c == ACK)  && flag_STR;
assign STR2STP_start   = (state_c == STR)  && flag_STP;
assign STP2IDLE_start  = (state_c == STP)  && flag_IDLE;

//**************************************
//     设计输出，一个always块一个信号
//**************************************

// STR 状态对时钟进行计数
always @(posedge clk or negedge rst_n) begin
  if(~rst_n) begin
    STR_cntclk     <= 16'd0;
    STR_cntclkdown <= 16'd0;
  end
  else if(flag_IDLE) begin
    STR_cntclk     <= 16'd0;
    STR_cntclkdown <= 16'd0;
  end
  else if (state_c == STR && ({clk_out_reg0,clk_out_reg1} == 2'b10))begin
    STR_cntclk <= STR_cntclk + 1'b1;
  end
  else if (state_c == STR && ({clk_out_reg0,clk_out_reg1} == 2'b01)) begin
    STR_cntclkdown <= STR_cntclkdown + 1'b1;
  end
  else begin
    STR_cntclk     <= STR_cntclk;
    STR_cntclkdown <= STR_cntclkdown;
  end
end

// STR 状态通过输出时钟个数对应寄存角度值和状态转移信号；
always @(posedge clk_out_rev or negedge rst_n) begin
  if(~rst_n) begin
    angle <= 26'd0;
    data_crc <= 6'd0;
    error <= 2'b11;
    read_done <= 1'b0;
  end
  else begin
    case(STR_cntclk)
      3:begin
        angle[25] <= data_in_reg1;
      end
      4:begin
        angle[24] <= data_in_reg1;
      end
      5:begin
        angle[23] <= data_in_reg1;
      end
      6:begin
        angle[22] <= data_in_reg1;
      end
      7:begin
        angle[21] <= data_in_reg1;
      end
      8:begin
        angle[20] <= data_in_reg1;
      end
      9:begin
        angle[19] <= data_in_reg1;
      end
      10:begin
        angle[18] <= data_in_reg1;
      end
      11:begin
        angle[17] <= data_in_reg1;
      end
      12:begin
        angle[16] <= data_in_reg1;
      end
      13:begin
        angle[15] <= data_in_reg1;
      end
      14:begin
        angle[14] <= data_in_reg1;
      end
      15:begin
        angle[13] <= data_in_reg1;
      end
      16:begin
        angle[12] <= data_in_reg1;
      end
      17:begin
        angle[11] <= data_in_reg1;
      end
      18:begin
        angle[10] <= data_in_reg1;
      end
      19:begin
        angle[9] <= data_in_reg1;
      end
      20:begin
        angle[8] <= data_in_reg1;
      end
      21:begin
        angle[7] <= data_in_reg1;
      end
      22:begin
        angle[6] <= data_in_reg1;
      end
      23:begin
        angle[5] <= data_in_reg1;
      end
      24:begin
        angle[4] <= data_in_reg1;
      end
      25:begin
        angle[3] <= data_in_reg1;
      end
      26:begin
        angle[2] <= data_in_reg1;
      end
      27:begin
        angle[1] <= data_in_reg1;
      end
      28:begin
        angle[0] <= data_in_reg1;
      end
      29:begin
        error[1] <= data_in_reg1;
      end
      30:begin
        error[0] <= data_in_reg1;
        read_done <= 1'b1;
      end
      31:begin
        data_crc[5] <= ~data_in_reg1;
        read_done <= 1'b0;
      end
      32:begin
        data_crc[4] <= ~data_in_reg1;
      end
      33:begin
        data_crc[3] <= ~data_in_reg1;
      end
      34:begin
        data_crc[2] <= ~data_in_reg1;
      end
      35:begin
        data_crc[1] <= ~data_in_reg1;
      end
      36:begin
        data_crc[0] <= ~data_in_reg1;
      end
      default:begin
        angle <= angle;
        error <= error;
        data_crc <= data_crc;
        read_done <= read_done;
      end
    endcase
  end
end

reg read_done0;
reg read_done1;

always @(posedge clk) begin
  read_done0 <= read_done;
  read_done1 <= read_done0;
end

always@ (posedge clk or negedge rst_n) begin
  if(~rst_n) begin
    crc_en <= 1'b0;
  end
  else if({read_done0,read_done1 == 2'b10}) begin
    crc_en <= 1'b1;
  end
  else begin
    crc_en <= 1'b0;
  end
end


endmodule
