
`timescale 1 ns / 10 ps
//////////////////////////////////////////////////////////////////////////////////
// Company: DMT
// Engineer: V
// Create Date: 2024/12/19 14:22
// Design Name: uart_control
// Module Name: uart_control
// Project Name: demo_1st_top
// Target Devices: Control Board V3
// Tool Versions: TD 5.6.2
// Description: 需要根据指令确定发出的DATA ID，根据不同的DATA ID控制接收的长度，
// Dependencies: tawa_control
// Revision:1.0
// Revision 1.01 - File Created
// Additional Comments: 以及数据的对应信息，并且要注意，数据是最低位先进来
//////////////////////////////////////////////////////////////////////////////////
module uart_control(
//system
  input          clk,
  input          rst_n,
//input
  input    [7:0] data_in,      //串口接受的数据，需要处理
  input          flag_recv,    //每次接受完成一个包，变高一次,持续一个BSP_CNT
  input          key_in,          //每当key=1时，发送一次读取请求 
//output
	 output        flag_send,    //串口发送使能
	 output  [7:0] data_out,     //串口发送的数据，用于获取角度值
   output  [7:0] SF_data_out,
   output  [7:0] REQUEST_out,
   output  [7:0] ALMC_out,
   output [23:0] turn_data_out,
   output  [7:0] ENID_out,
	 output [23:0] angle_uart    //最终获得的角度值
);

/**********  wire define  ***********/
wire                   p_flag_recv;   //捕获flag_recv上升沿，表示一次数据接受完成，可以进行数据处理

/**********   reg define  ***********/
reg [7:0] REQUEST/*synthesis keep*/;    //根据MCU的命令，定义不同的请求命令
reg [7:0] key_cnt/*synthesis keep*/;    //寄存按键次数，用于调用请求信号
reg [7:0] data_len;   //根据不同的数据ID，确定数据长度
reg [7:0] SF_data/*synthesis keep*/;      // 角度值状态位
reg [7:0] CRC_data/*synthesis keep*/;     // 角度值校验位

reg [7:0] ENID/*synthesis keep*/;
reg [7:0] ALMC/*synthesis keep*/;
reg [23:0] angle_data/*synthesis keep*/;
reg [23:0] turn_data/*synthesis keep*/;

reg [7:0] data_out_reg;
reg flag_send_reg/*synthesis keep*/;
reg flag_send_reg0;
reg flag_send_reg1;
reg flag_send_reg2;
reg flag_send_reg3;
reg key_in0;
reg key_in1;

reg        flag_recv1;
reg        flag_recv2;     //寄存flag_recv，用于捕捉上升沿
reg  [7:0] data_in_reg1;
reg  [7:0] data_in_reg2/*synthesis keep*/;   //寄存data_in,用于对齐数据计数data_comb 和数据data_in
reg  [7:0] comb_cnt;       //用于计数当前包处于第几个

reg        flag_valid/*synthesis keep*/;     //第一个包是否为帧头标志位，当flag_valid为1时，可以进行数据处理操作
reg        flag_check/*synthesis keep*/;     //当1时，表明一次传输完成，可以进行总校验

/**********  assign part  ***********/
assign p_flag_recv = flag_recv1 & (~flag_recv2);    //用于捕捉flag_recv上升沿
assign angle_uart  = angle_data;
// assign data_out = data_out_reg;
assign data_out = REQUEST;
assign flag_send = flag_send_reg3;

assign SF_data_out = SF_data;
assign REQUEST_out = REQUEST;
assign ALMC_out = ALMC;
assign turn_data_out = turn_data;
assign ENID_out = ENID;

// 根据不同的指令（通过MCU给与，先用按键的次数充当）
//
// 设定不同的请求信号
always @(posedge clk or negedge rst_n) begin
  if(~rst_n) begin
    key_cnt <= 1'b0;
  end
  else if(key_in1 == 1'b1) begin
    key_cnt <= key_cnt + 1'b1;
  end
  else begin
    key_cnt <= key_cnt;
  end
end

// 注意发数的顺序
always @(posedge clk or negedge rst_n) begin
  if(~rst_n) begin
    REQUEST <= {5'b00000,3'b010};
    data_len <= 8'd6;
  end
  else begin
    case(key_cnt)
      8'd2:begin  //DATA ID1
        REQUEST <= {5'b10001,3'b010};
        data_len <= 8'd6;
      end
      8'd3:begin  //DATA ID2
        REQUEST <= {5'b10010,3'b010};
        data_len <= 8'd4;
      end
      8'd4:begin  //DATA ID3
        REQUEST <= {5'b00011,3'b010};
        data_len <=8'd11;
      end
      8'd5:begin  //DATA ID7
        REQUEST <= {5'b10111,3'b010};
        data_len <= 8'd6;
      end
      8'd6:begin  //DATA ID8
        REQUEST <= {5'b11000,3'b010};
        data_len <= 8'd6;
      end
      8'd7:begin  //DATA IDC
        REQUEST <= {5'b01100,3'b010};
        data_len <= 8'd6;
      end
      default:begin
        REQUEST <= {5'b00000,3'b010};
        data_len <= 8'd6;
      end
    endcase
  end
end

/**************************************
    捕获上升沿或对齐数据
**************************************/
always @(posedge clk or negedge rst_n) begin
  if(~rst_n) begin
    flag_recv1   <= 1'b0;
	  flag_recv2   <= 1'b0;
    data_in_reg1 <= 32'd0;
	  data_in_reg2 <= 32'd0;
    key_in0 <= 1'b0;
    key_in1 <= 1'b0;
    flag_send_reg0 <= 1'b0;
    flag_send_reg1 <= 1'b0;
    flag_send_reg2 <= 1'b0;
    flag_send_reg3 <= 1'b0;
  end
  else begin
    flag_recv1   <= flag_recv;
	  flag_recv2   <= flag_recv1;
    data_in_reg1 <= data_in;
	  data_in_reg2 <= data_in_reg1;
    key_in0 <= key_in;
    key_in1 <= key_in0;
    flag_send_reg0 <= flag_send_reg;
    flag_send_reg1 <= flag_send_reg0;
    flag_send_reg2 <= flag_send_reg1;
    flag_send_reg3 <= flag_send_reg2;
  end
end
/**************************************
             发送读取请求  
**************************************/
always @(posedge clk or negedge rst_n) begin
  if(~rst_n) begin
    data_out_reg <= 8'd0;
  end
  else if(flag_send_reg) begin
    data_out_reg <= REQUEST;      //发送读取请求
  end
  else begin
    data_out_reg <= data_out_reg;
  end
end
/**************************************
            读取初始化操作
**************************************/
always @(posedge clk or negedge rst_n) begin
  if(~rst_n) begin
    comb_cnt <= 1'b0;
	  flag_send_reg <= 1'b0;
	  flag_check <= 1'b0;
  end
  else if(key_in) begin                  //发送一次读取请求
    flag_send_reg <= 1'b1;
  end
  else if(p_flag_recv) begin          //有数据进来时，打开数据包计数模块
    comb_cnt <= comb_cnt + 1'b1;
  end
  else if(comb_cnt == data_len) begin    //comb_cnt = 12 only keep 1 clk
    comb_cnt <= 1'b0;
	  flag_check <= 1'b1;               //接受到最后一个包时，输出总校验开始标志
  end
  else begin
    comb_cnt <= comb_cnt;
	  flag_send_reg <= 1'b0;
	  flag_check <= 1'b0;
  end
end

/**************************************
        判断第一个包是否为帧头0x1A    
**************************************/
always @(posedge clk or negedge rst_n) begin
  if(~rst_n) begin
    flag_valid <= 1'b0;
  end
  else if((comb_cnt == 8'd1) && (data_in_reg2 == REQUEST)) begin
	  flag_valid <= 1'b1;                //flag_valid 持续时间需要考虑
  end
  else if(comb_cnt == 8'd0) begin      //当flag_valid为1时，才可以进行数据处理操作
    flag_valid <= 1'b0;
  end
  else begin
    flag_valid <= flag_valid;
  end
end

/**************************************
   检测到帧头时，把剩下的角度值数据组包  
**************************************/
always @(posedge clk or negedge rst_n) begin
  if(~rst_n) begin
    angle_data <= 24'd0;
    SF_data    <= 8'd0;
    CRC_data   <= 8'd0;
    ENID       <= 8'd0;
    turn_data  <= 8'd0;
    ALMC       <= 8'd0;
  end
  else if(flag_valid) begin    //当flag_valid为1时，才可以进行数据处理操作
    if(key_cnt == 8'd3) begin
      case(comb_cnt)
        4'd2:SF_data  <= data_in_reg2;
        4'd3:ENID     <= data_in_reg2;
        4'd4:CRC_data <= data_in_reg2;
        default:;
      endcase
      angle_data <= 24'd0;
      turn_data <= 24'd0;
      ALMC <= 8'd0;
    end
    else if(key_cnt == 8'd4) begin
      case(comb_cnt)
        8'd2: SF_data           <= data_in_reg2;
        8'd3: angle_data  [7:0] <= data_in_reg2;
        8'd4: angle_data [15:8] <= data_in_reg2;
        8'd5: angle_data[23:16] <= data_in_reg2;
        8'd6: ENID              <= data_in_reg2;
        8'd7: turn_data  [7:0]  <= data_in_reg2;
        8'd8: turn_data [15:8]  <= data_in_reg2;
        8'd9: turn_data[23:16]  <= data_in_reg2;
        8'd10:ALMC              <= data_in_reg2;
        8'd11:CRC_data          <= data_in_reg2;
        default:;
      endcase
    end
    else if(key_cnt == 8'd2) begin
      case(comb_cnt)
        4'd2:SF_data          <= data_in_reg2;
        4'd3:turn_data[7:0] <= data_in_reg2;
        4'd4:turn_data[15:8] <= data_in_reg2;
        4'd5:turn_data[23:16] <= data_in_reg2;
        4'd6:CRC_data         <= data_in_reg2;
        default:;
      endcase
      angle_data <= 24'd0;
      ALMC <= 8'd0;
      ENID <= 8'd0;
    end
    else begin
      case(comb_cnt)
	      4'd2:SF_data <= data_in_reg2;
		    4'd3:angle_data[7:0] <= data_in_reg2;
	  	  4'd4:angle_data[15:8]  <= data_in_reg2;
		    4'd5:angle_data[23:16]   <= data_in_reg2;    //把第一路4x8 bit数据组合成32bit的角度值
		    4'd6:CRC_data           <= data_in_reg2;    //寄存第一路角度值的有效位
		  default:;
	    endcase
      turn_data <= 24'd0;
      ALMC <= 8'd0;
      ENID <= 8'd0;
    end
  end
  else begin
    SF_data    <= SF_data;
	  angle_data <= angle_data;
	  CRC_data   <= CRC_data;
    ENID       <= ENID;
    turn_data  <= turn_data;
    ALMC       <= ALMC;
  end
end


endmodule
