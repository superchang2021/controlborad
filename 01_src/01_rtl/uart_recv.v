/*******************************************************
    名称：uart_recv
	 作者：常仁威
	 时间：2024.09.10
	 功能：串口接收模块
	 测试平台：FA303
	 版本：1.0
	 上次修改时间：2024.09.10
*******************************************************/
module uart_recv(
//system
  input  clk,
  input  rst_n,
//input
  input  uart_rxd,                           //串口接收数据线
//output
    output reg                uart_done,    //串口接受完成标志
	 output reg [7:0] uart_data     //串口接受的数据
);
/**********  parameter define  ***********/
localparam BPS_CNT     = 28'd100_000_000/24'd2500000; ////为得到指定波特率，需要对系统时钟计数BPS_CNT次

/**********  wire define  ***********/
wire       start_flag;

/**********   reg define  ***********/
reg                    rxd_reg0;
reg                    rxd_reg1;    //稳定串口接收数据
reg                    rxd_in0;
reg                    rxd_in1;     //寄存串口数据，判断有效用
reg                    rx_flag;     //接收过程标志信号
reg             [15:0] clk_cnt;     //系统时钟计数器
reg              [3:0] rx_cnt;      //接收数据计数器
reg    [7:0] rxdata;      //寄存接收的数据

/**********  assign part  ***********/
assign  start_flag = rxd_in1 & (~rxd_in0);    //捕获接收端口下降沿(起始位)，得到一个时钟周期的脉冲信号

/**************************************
    输入数据相对于系统时钟是个异步信号
	      因此也需要对其进行同步            
**************************************/
always @(posedge clk or negedge rst_n) begin
  if(~rst_n) begin
    rxd_reg0 <= 1'b0;
    rxd_reg1 <= 1'b0;
  end
  else begin
    rxd_reg0 <= uart_rxd;
    rxd_reg1 <= rxd_reg0;
  end
end
/**************************************
   对UART接收端口的数据延迟两个时钟周期
**************************************/
always @(posedge clk or negedge rst_n) begin
  if(~rst_n) begin
    rxd_in0 <= 1'b0;
	 rxd_in1 <= 1'b0;
  end
  else begin
    rxd_in0 <= rxd_reg1;
	 rxd_in1 <= rxd_in0;
  end
end
/**************************************
 当脉冲信号start_flag到达时，进入接收过程
**************************************/
always @(posedge clk or negedge rst_n) begin
  if(~rst_n) begin
    rx_flag <= 1'b0;
  end
  else begin
    if(start_flag) begin     //检测到起始位，进入接收过程，标志位rx_flag拉高
	   rx_flag <= 1'b1;
	 end
	 else if((rx_cnt == 4'd9) && (clk_cnt == BPS_CNT/2)) begin
	   rx_flag <= 1'b0;      //计数到停止位中间时，停止接收过程
	 end
	 else begin
	   rx_flag <= rx_flag;
	 end
  end
end
/**************************************
   进入接收过程后，启动系统时钟计数器
           与接收数据计数器          
**************************************/
always @(posedge clk or negedge rst_n) begin
  if(~rst_n) begin
    clk_cnt <= 1'b0;
	 rx_cnt  <= 1'b0;
  end
  else if(rx_flag) begin                //处于接收过程
    if(clk_cnt <= BPS_CNT - 1) begin
	   clk_cnt <= clk_cnt +1'b1;
		rx_cnt  <= rx_cnt;
    end
	 else begin
	   clk_cnt <= 1'b0;                  //对系统时钟计数达一个波特率周期后清零
		rx_cnt  <= rx_cnt +1'b1;          //此时接收数据计数器加1
	 end
  end
  else begin
    clk_cnt <= 1'b0;                    //接收过程结束，计数器清零
	 rx_cnt  <= 1'b0;
  end
end
/**************************************
 根据接收数据计数器来寄存uart接收端口数据     
**************************************/
always @(posedge clk or negedge rst_n) begin
  if(~rst_n) begin
    rxdata <= 1'b0;
  end
  else if(rx_flag) begin              //系统处于接收过程
    if(clk_cnt == BPS_CNT/2) begin    //判断系统时钟计数器计数到数据位中间？原因是？？？
	   case(rx_cnt)
		  4'd1: rxdata[0] <= rxd_in1;   //寄存数据位最低位
		  4'd2: rxdata[1] <= rxd_in1;
		  4'd3: rxdata[2] <= rxd_in1;
		  4'd4: rxdata[3] <= rxd_in1;
		  4'd5: rxdata[4] <= rxd_in1;
		  4'd6: rxdata[5] <= rxd_in1;
		  4'd7: rxdata[6] <= rxd_in1;
		  4'd8: rxdata[7] <= rxd_in1;   //寄存数据位最高位
		  default: ;
		endcase
	 end
	 else begin
	   rxdata <= rxdata;
	 end
  end
  else begin
    rxdata <= 1'b0;
  end
end
/**************************************
       数据接收完毕后给出标志信号并
          寄存输出接收到的数据     
**************************************/
always @(posedge clk or negedge rst_n) begin
  if(~rst_n) begin
    uart_data <= 1'b0;
	 uart_done <= 1'b0;
  end
  else if(rx_cnt == 4'd9) begin    //接收数据计数器计数到停止位时 
    uart_data <= rxdata;           //寄存输出接收到的数据
	 uart_done <= 1'b1;             //并将接收完成标志位拉高
  end
  else begin
    uart_data <= uart_data;
	 uart_done <= 1'b0;
  end
end

endmodule
