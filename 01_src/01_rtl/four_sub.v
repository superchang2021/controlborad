
`timescale 1 ns / 10 ps
//////////////////////////////////////////////////////////////////////////////////
// Company: DMT
// Engineer: V
// Create Date: 2024/12/17 16:01
// Design Name: four_sub
// Module Name: four_sub
// Project Name: demo_1st_top
// Target Devices: Control Board V3
// Tool Versions: TD 5.6.2
// Description: four sub division
// Dependencies: encoder_control
// Revision:1.0
// Revision 1.01 - File Created
// Additional Comments:
//////////////////////////////////////////////////////////////////////////////////
module four_sub(
  input                  clk,       // 100MHz clk
  input                  rst_n,     // reset

  input                  ain,       // encoder data in a
  input                  bin,       // encoder data in b
  input                  zin,       // encoder data in z

    output signed [31:0] sub_cnt    // abz data out
);
// reg define
reg               ain1;           // a reg
reg               bin1;           // b reg
reg               zin1,zin2;      // z reg
reg         [1:0] cur;            // current state
reg         [1:0] pre;            // pre state
reg               forward;        // CW
reg               reverse;        // CCW
reg signed [31:0] sub_cnt_reg;    // sub_cnt reg
reg               flag;           // z posedge flag
reg         [7:0] cnt;            // cnt for z posedge
// assign define
assign sub_cnt = sub_cnt_reg;
//////////////////////////////////////////////////////////////////////////////////
//                            data catch & state judge
//////////////////////////////////////////////////////////////////////////////////
always @(posedge clk or negedge rst_n) begin
  if(~rst_n) begin
    ain1    <= 1'b1;
    bin1    <= 1'b1;
    zin1    <= 1'b1;
    zin2    <= 1'b1;
    cur     <= 2'b11;
    pre     <= 2'b11;
    forward <= 1'b1;
    reverse <= 1'b1;
  end
  else begin
	ain1    <= ain;
	bin1    <= bin;
	zin1    <= zin;
	zin2    <= zin1;
	cur     <= {ain1, bin1};       
	pre     <= cur;  
    forward <= (pre==2'b00 && cur==2'b10)||(pre==2'b10 && cur==2'b11)||(pre==2'b11 && cur==2'b01)||(pre==2'b01 && cur==2'b00);
    reverse <= (pre==2'b00 && cur==2'b01)||(pre==2'b01 && cur==2'b11)||(pre==2'b11 && cur==2'b10)||(pre==2'b10 && cur==2'b00);
  end  	
end
//////////////////////////////////////////////////////////////////////////////////
//                             z signal capture
//////////////////////////////////////////////////////////////////////////////////
always @(posedge clk or negedge rst_n) begin
  if(~rst_n) begin
    flag <= 0;
    cnt <= 8'd0;
  end
// z posedge capture
  else if( zin2 == 1'b0 && zin1 == 1'b1 ) begin
    flag <= 1;
    cnt <= cnt + 1'b1;
  end
  else begin
    flag <=0;
    cnt <= cnt;
  end
end
//////////////////////////////////////////////////////////////////////////////////
//                                cnt calc
//////////////////////////////////////////////////////////////////////////////////
always@(posedge clk or negedge rst_n) begin
  if(~rst_n) begin
    sub_cnt_reg <= 32'd0;
  end
// first z posedge,clear cnt
  else if( (cnt==1'b1) && (flag==1'b1) ) begin
    sub_cnt_reg <= 32'd0;
  end
// when cnt < -1048576,clear cnt
  else if( (sub_cnt_reg[31] == 1'b1) && (sub_cnt_reg < -32'd1048575) ) begin
    sub_cnt_reg <= 32'd0;
  end
// when cnt > 1048576,clear cnt
  else if( (sub_cnt_reg[31] == 1'b0) && (sub_cnt_reg > 32'd1048575) ) begin
    sub_cnt_reg <= 32'd0;
  end
// calc cnt using state judge
  else if(forward) begin
    sub_cnt_reg <= sub_cnt_reg + 1'd1;
  end
  else if(reverse) begin
    sub_cnt_reg <= sub_cnt_reg - 1'd1;
  end
  else begin
    sub_cnt_reg <= sub_cnt_reg;
  end
end

endmodule
