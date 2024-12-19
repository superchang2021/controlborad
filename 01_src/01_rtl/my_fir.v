// ------------------------------------------------------------------------
// name:my_fir
// author:chang
// data:20241207
// function: fir filter
`timescale 1ns/1ps

module my_fir(
  input clk,
  input rst_n,

  input signed [15:0] data_in,    // 串行输入（适合数据量大的）
  input           data_valid,
  output signed [15:0] data_out,
  output           data_ready
);

// coff define
reg signed [9:0] h0;
reg signed [9:0] h1;
reg signed [9:0] h2;
reg signed [9:0] h3;
reg signed [9:0] h4;
reg signed [9:0] h5;
reg signed [9:0] h6;
reg signed [9:0] h7;
reg signed [9:0] h8;
reg signed [9:0] h9;
reg signed [9:0] h10;
reg signed [9:0] h11;
reg signed [9:0] h12;
reg signed [9:0] h13;
reg signed [9:0] h14;
reg signed [9:0] h15;
reg signed [9:0] h16;
reg signed [9:0] h17;
reg signed [9:0] h18;
reg signed [9:0] h19;
reg signed [9:0] h20;
reg signed [9:0] h21;
reg signed [9:0] h22;
reg signed [9:0] h23;
reg signed [9:0] h24;
reg signed [9:0] h25;
reg signed [9:0] h26;
reg signed [9:0] h27;
reg signed [9:0] h28;
reg signed [9:0] h29;
reg signed [9:0] h30;
reg signed [9:0] h31;
// xn
reg signed [15:0]  x0;
reg signed [15:0]  x1;
reg signed [15:0]  x2;
reg signed [15:0]  x3;
reg signed [15:0]  x4;
reg signed [15:0]  x5;
reg signed [15:0]  x6;
reg signed [15:0]  x7;
reg signed [15:0]  x8;
reg signed [15:0]  x9;
reg signed [15:0] x10;
reg signed [15:0] x11;
reg signed [15:0] x12;
reg signed [15:0] x13;
reg signed [15:0] x14;
reg signed [15:0] x15;
reg signed [15:0] x16;
reg signed [15:0] x17;
reg signed [15:0] x18;
reg signed [15:0] x19;
reg signed [15:0] x20;
reg signed [15:0] x21;
reg signed [15:0] x22;
reg signed [15:0] x23;
reg signed [15:0] x24;
reg signed [15:0] x25;
reg signed [15:0] x26;
reg signed [15:0] x27;
reg signed [15:0] x28;
reg signed [15:0] x29;
reg signed [15:0] x30;
reg signed [15:0] x31;
// coff * xn
reg signed [25:0]  xh0 ;
reg signed [25:0]  xh1 ;
reg signed [25:0]  xh2 ;
reg signed [25:0]  xh3 ;
reg signed [25:0]  xh4 ;
reg signed [25:0]  xh5 ;
reg signed [25:0]  xh6 ;
reg signed [25:0]  xh7 ;
reg signed [25:0]  xh8 ;
reg signed [25:0]  xh9 ;
reg signed [25:0]  xh10;
reg signed [25:0]  xh11;
reg signed [25:0]  xh12;
reg signed [25:0]  xh13;
reg signed [25:0]  xh14;
reg signed [25:0]  xh15;
reg signed [25:0]  xh16;
reg signed [25:0]  xh17;
reg signed [25:0]  xh18;
reg signed [25:0]  xh19;
reg signed [25:0]  xh20;
reg signed [25:0]  xh21;
reg signed [25:0]  xh22;
reg signed [25:0]  xh23;
reg signed [25:0]  xh24;
reg signed [25:0]  xh25;
reg signed [25:0]  xh26;
reg signed [25:0]  xh27;
reg signed [25:0]  xh28;
reg signed [25:0]  xh29;
reg signed [25:0]  xh30;
reg signed [25:0]  xh31;

reg data_ready_reg0;
reg data_ready_reg1;

reg signed [15:0] data_out_reg;

reg signed [31:0] xh_add;

assign data_out = data_valid ? data_out_reg : data_out;
assign data_ready = data_ready_reg1;

// coff inialize
always @(posedge clk or negedge rst_n)begin
  if(~rst_n)begin
    h0  <= 10'd0;
    h1  <= 10'd0;
    h2  <= 10'd0;
    h3  <= 10'd0;
    h4  <= 10'd0;
    h5  <= 10'd0;
    h6  <= 10'd0;
    h7  <= 10'd0;
    h8  <= 10'd0;
    h9  <= 10'd0;
    h10 <= 10'd0;
    h11 <= 10'd0;
    h12 <= 10'd0;
    h13 <= 10'd0;
    h14 <= 10'd0;
    h15 <= 10'd0;
    h16 <= 10'd0;
    h17 <= 10'd0;
    h18 <= 10'd0;
    h19 <= 10'd0;
    h20 <= 10'd0;
    h21 <= 10'd0;
    h22 <= 10'd0;
    h23 <= 10'd0;
    h24 <= 10'd0;
    h25 <= 10'd0;
    h26 <= 10'd0;
    h27 <= 10'd0;
    h28 <= 10'd0;
    h29 <= 10'd0;
    h30 <= 10'd0;
    h31 <= 10'd0;
  end
  else begin
    h0  <= 10'd25;
    h1  <= 10'd12;
    h2  <= 10'd15;
    h3  <= 10'd18;
    h4  <= 10'd21;
    h5  <= 10'd24;
    h6  <= 10'd27;
    h7  <= 10'd30;
    h8  <= 10'd33;
    h9  <= 10'd36;
    h10 <= 10'd38;
    h11 <= 10'd40;
    h12 <= 10'd42;
    h13 <= 10'd43;
    h14 <= 10'd44;
    h15 <= 10'd45;
    h16 <= 10'd45;
    h17 <= 10'd44;
    h18 <= 10'd43;
    h19 <= 10'd42;
    h20 <= 10'd40;
    h21 <= 10'd38;
    h22 <= 10'd36;
    h23 <= 10'd33;
    h24 <= 10'd30;
    h25 <= 10'd27;
    h26 <= 10'd24;
    h27 <= 10'd21;
    h28 <= 10'd18;
    h29 <= 10'd15;
    h30 <= 10'd12;
    h31 <= 10'd25;
  end
end
// 流水操作
always @(posedge clk or negedge rst_n)begin
  if(~rst_n) begin
     x0 <= 16'd0;
     x1 <= 16'd0;
     x2 <= 16'd0;
     x3 <= 16'd0;
     x4 <= 16'd0;
     x5 <= 16'd0;
     x6 <= 16'd0;
     x7 <= 16'd0;
     x8 <= 16'd0;
     x9 <= 16'd0;
    x10 <= 16'd0;
    x11 <= 16'd0;
    x12 <= 16'd0;
    x13 <= 16'd0;
    x14 <= 16'd0;
    x15 <= 16'd0;
    x16 <= 16'd0;
    x17 <= 16'd0;
    x18 <= 16'd0;
    x19 <= 16'd0;
    x20 <= 16'd0;
    x21 <= 16'd0;
    x22 <= 16'd0;
    x23 <= 16'd0;
    x24 <= 16'd0;
    x25 <= 16'd0;
    x26 <= 16'd0;
    x27 <= 16'd0;
    x28 <= 16'd0;
    x29 <= 16'd0;
    x30 <= 16'd0;
    x31 <= 16'd0;
  end
  else if(data_valid)begin // 当数据有效时
     x0 <= data_in;
     x1 <= x0;
     x2 <= x1;
     x3 <= x2;
     x4 <= x3;
     x5 <= x4;
     x6 <= x5;
     x7 <= x6;
     x8 <= x7;
     x9 <= x8;
    x10 <= x9;
    x11 <= x10;
    x12 <= x11;
    x13 <= x12;
    x14 <= x13;
    x15 <= x14;
    x16 <= x15;
    x17 <= x16;
    x18 <= x17;
    x19 <= x18;
    x20 <= x19;
    x21 <= x20;
    x22 <= x21;
    x23 <= x22;
    x24 <= x23;
    x25 <= x24;
    x26 <= x25;
    x27 <= x26;
    x28 <= x27;
    x29 <= x28;
    x30 <= x29;
    x31 <= x30;
  end
end
// coff * xn
always @(posedge clk or negedge rst_n)begin
  if(~rst_n) begin
    xh0 <= 26'd0;
    xh1 <= 26'd0;
    xh2 <= 26'd0;
    xh3 <= 26'd0;
    xh4 <= 26'd0;
    xh5 <= 26'd0;
    xh6 <= 26'd0;
    xh7 <= 26'd0;
    xh8 <= 26'd0;
    xh9 <= 26'd0;
    xh10<= 26'd0;
    xh11<= 26'd0;
    xh12<= 26'd0;
    xh13<= 26'd0;
    xh14<= 26'd0;
    xh15<= 26'd0;
    xh16<= 26'd0;
    xh17<= 26'd0;
    xh18<= 26'd0;
    xh19<= 26'd0;
    xh20<= 26'd0;
    xh21<= 26'd0;
    xh22<= 26'd0;
    xh23<= 26'd0;
    xh24<= 26'd0;
    xh25<= 26'd0;
    xh26<= 26'd0;
    xh27<= 26'd0;
    xh28<= 26'd0;
    xh29<= 26'd0;
    xh30<= 26'd0;
    xh31<= 26'd0;
  end
  else if(data_valid)begin  // 这些乘法可以根据系数来进行优化
    xh0 <= x0  * h0 ;
    xh1 <= x1  * h1 ;
    xh2 <= x2  * h2 ;
    xh3 <= x3  * h3 ;
    xh4 <= x4  * h4 ;
    xh5 <= x5  * h5 ;
    xh6 <= x6  * h6 ;
    xh7 <= x7  * h7 ;
    xh8 <= x8  * h8 ;
    xh9 <= x9  * h9 ;
    xh10<= x10 * h10;
    xh11<= x11 * h11;
    xh12<= x12 * h12;
    xh13<= x13 * h13;
    xh14<= x14 * h14;
    xh15<= x15 * h15;
    xh16<= x16 * h16;
    xh17<= x17 * h17;
    xh18<= x18 * h18;
    xh19<= x19 * h19;
    xh20<= x20 * h20;
    xh21<= x21 * h21;
    xh22<= x22 * h22;
    xh23<= x23 * h23;
    xh24<= x24 * h24;
    xh25<= x25 * h25;
    xh26<= x26 * h26;
    xh27<= x27 * h27;
    xh28<= x28 * h28;
    xh29<= x29 * h29;
    xh30<= x30 * h30;
    xh31<= x31 * h31;
  end
  else begin
    xh0 <= xh0;
    xh1 <= xh1;
    xh2 <= xh2;
    xh3 <= xh3;
    xh4 <= xh4;
    xh5 <= xh5;
    xh6 <= xh6;
    xh7 <= xh7;
    xh8 <= xh8;
    xh9 <= xh9;
    xh10<= xh10;
    xh11<= xh11;
    xh12<= xh12;
    xh13<= xh13;
    xh14<= xh14;
    xh15<= xh15;
    xh16<= xh16;
    xh17<= xh17;
    xh18<= xh18;
    xh19<= xh19;
    xh20<= xh20;
    xh21<= xh21;
    xh22<= xh22;
    xh23<= xh23;
    xh24<= xh24;
    xh25<= xh25;
    xh26<= xh26;
    xh27<= xh27;
    xh28<= xh28;
    xh29<= xh29;
    xh30<= xh30;
    xh31<= xh31;
  end
end
// 求和
always @(posedge clk or negedge rst_n)begin
  if(~rst_n) begin
    xh_add <= 32'd0;
  end
  else if(data_valid)begin
    xh_add <= xh0 + xh1 + xh2 + xh3 + xh4 + xh5 + xh6 + xh7 + xh8 + xh9 + xh10 + xh11 + xh12 + xh13 + xh14 + xh15 + xh16 + xh17 + xh18 + xh19 + xh20 + xh21 + xh22 + xh23 + xh24+ xh25 + xh26 + xh27 + xh28 + xh29 + xh30 + xh31;
  end
  else begin
    xh_add <= xh_add;
  end
end
// 截取高位输出
always @(posedge clk or negedge rst_n)begin
  if(~rst_n) begin
    data_out_reg <= 16'd0;
  end
  else if(data_valid)begin
    data_out_reg <= xh_add[31:16];
  end
  else begin
    data_out_reg <= data_out_reg;
  end
end
// 寄存有效信号
always @(posedge clk or negedge rst_n)begin
  if(~rst_n) begin
    data_ready_reg0 <= 1'b0;
    data_ready_reg1 <= 1'b0;
  end
  else begin
    data_ready_reg0 <= data_valid;
    data_ready_reg1 <= data_ready_reg0;
  end
end

endmodule
