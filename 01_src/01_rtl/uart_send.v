/*******************************************************
    名称：uart_send
	 作者：常仁威
	 时间：2024.09.10
	 功能：串口发送模块
	 测试平台：FA303
	 版本：1.0
	 上次修改时间：2024.09.10
*******************************************************/
module uart_send(
//system
  input  clk,
  input  rst_n,
//input
  input [7:0] uart_data/*synthesis keep*/,        //串口待发送的数据
  input       uart_send_en,     //串口发送使能
//output
    output  reg tx_flag,                  //发送过程标志信号
	 output  reg uart_txd                 //串口发送数据
);


/**********  parameter define  ***********/
localparam BPS_CNT  = 28'd100_000_000/24'd2500000;    //为得到指定波特率，对系统时钟计数BPS_CNT次

/**********  wire define  ***********/
wire  en_flag/*synthesis keep*/;     //发送使能标志位

/**********   reg define  ***********/
reg                  send_en0;
reg                  send_en1;      //寄存发送使能，判断有效用
reg  [7:0] tx_data;       //寄存发送数据
reg            [3:0] tx_cnt;        //发送数据寄存器
reg           [15:0] clk_cnt;       //系统时钟计数器

/**********  assign part  ***********/
assign  en_flag = send_en1 & (~send_en0);    //捕获uart_en上升沿，得到一个时钟周期的脉冲信号

/**************************************
对发送使能信号uart_send_en延迟两个时钟周期
**************************************/
always @(posedge clk or negedge rst_n) begin
  if(~rst_n) begin
    send_en0 <= 1'b0;
	  send_en1 <= 1'b0;
  end
  else begin
    send_en0 <= uart_send_en;
	  send_en1 <= send_en0;
  end
end
/**************************************
 当脉冲信号en_flag到达时,寄存待发送的数据，
             并进入发送过程
**************************************/
always @(posedge clk or negedge rst_n) begin
  if(~rst_n) begin
    tx_flag <= 1'b0;
	  tx_data <= 1'b0;
  end
  else if(en_flag) begin
    tx_flag <= 1'b1;
	  tx_data <= uart_data;
  end
  else if((tx_cnt == 4'd9) && (clk_cnt == BPS_CNT/2)) begin
    tx_flag <= 1'b0;
	  tx_data <= 1'b0;
  end
  else begin
    tx_flag <= tx_flag;
	  tx_data <= tx_data;
  end
end
/**************************************
   进入发送过程后，启动系统时钟计数器
           与发送数据计数器
**************************************/
always @(posedge clk or negedge rst_n) begin
  if(~rst_n) begin
    clk_cnt <= 1'b0;
	  tx_cnt  <= 1'b0;
  end
  else if(tx_flag) begin           //处于发送过程
    if(clk_cnt < BPS_CNT - 1'b1) begin
	   clk_cnt <= clk_cnt + 1'b1;
	   tx_cnt  <= tx_cnt;
	 end
	 else begin
	   clk_cnt <= 1'b0;             //对系统时钟计数达一个波特率周期后清零
	   tx_cnt  <= tx_cnt + 1'b1;    //此时发送数据计数器加1
	 end
  end
  else begin                       //发送过程结束
    clk_cnt <= 1'b0;
	  tx_cnt  <= 1'b0;
  end
end
/**************************************
  根据发送数据计数器来给uart发送端口赋值     
**************************************/
always @(posedge clk or negedge rst_n) begin
  if(~rst_n) begin
    uart_txd <= 1'b1;    //无数据传输默认为高电平
  end
  else if(tx_flag) begin
    case(tx_cnt)
	    4'd0:uart_txd <= 1'b0;          //起始位
		  4'd1:uart_txd <= tx_data[0];    //数据最低位
		  4'd2:uart_txd <= tx_data[1];
		  4'd3:uart_txd <= tx_data[2];
		  4'd4:uart_txd <= tx_data[3];
		  4'd5:uart_txd <= tx_data[4];
		  4'd6:uart_txd <= tx_data[5];
		  4'd7:uart_txd <= tx_data[6];
		  4'd8:uart_txd <= tx_data[7];    //数据位最高位
		  4'd9:uart_txd <= 1'b1;          //停止位
		default: ;
	 endcase
  end
  else begin
    uart_txd <= 1'b1;                 //空闲时发送端口为高电平
  end
end

endmodule
