
module biss_crc6(
  input [31:0] data_in/*synthesis keep*/,    //
  input crc_en/*synthesis keep*/,            //
    output [5:0] crc_outt/*synthesis keep*/,    //
  input rst_n,    //
  input clk    //
);

// 移植天时编码器的CRC校验C语言代码



reg [7:0] calc_i5/*synthesis keep*/;
reg [7:0] calc_i4/*synthesis keep*/;
reg [7:0] calc_i3/*synthesis keep*/;
reg [7:0] calc_i2/*synthesis keep*/;
reg [7:0] calc_i1/*synthesis keep*/;  //寄存器用来存中介变量

reg [31:0] calc_crc/*synthesis keep*/;  //输出的CRC校验值
reg [7:0] cnt_en/*synthesis keep*/;     //CRC校验使能

// assign define
assign crc_outt = calc_crc[5:0];      // 最终输出的CRC校验位，6bit
//`define CRC_TABLE [0:63] = 32'h00,32'h03,32'h06,32'h05,32'h0c,32'h0f,32'h0a,32'h09,32'h18,32'h1b,32'h1e,32'h1d,32'h14,32'h17,32'h12,32'h11,32'h30,32'h33,32'h36,32'h35,32'h3c,32'h3f,32'h3a,32'h39,32'h28,32'h2b,32'h2e,32'h2d,32'h24,32'h27,32'h22,32'h21,32'h23,32'h20,32'h25,32'h26,32'h2f,32'h2c,32'h29,32'h2a,32'h3b,32'h38,32'h3d,32'h3e,32'h37,32'h34,32'h31,32'h32,32'h13,32'h10,32'h15,32'h16,32'h1f,32'h1c,32'h19,32'h1a,32'h0b,32'h08,32'h0d,32'h0e,32'h07,32'h04,32'h01,32'h02;
reg [31:0] CRC_TABLE [0:64];    //CRC校验表

always @(posedge clk) begin    //CRC校验表初始化（只能用这种方法，其他方法都会出错）
  CRC_TABLE[0] <= 32'h00;
  CRC_TABLE[1] <= 32'h03;
  CRC_TABLE[2] <= 32'h06;
  CRC_TABLE[3] <= 32'h05;
  CRC_TABLE[4] <= 32'h0c;
  CRC_TABLE[5] <= 32'h0f;
  CRC_TABLE[6] <= 32'h0a;
  CRC_TABLE[7] <= 32'h09;

  CRC_TABLE[8] <= 32'h18;
  CRC_TABLE[9] <= 32'h1b;
  CRC_TABLE[10] <= 32'h1e;
  CRC_TABLE[11] <= 32'h1d;
  CRC_TABLE[12] <= 32'h14;
  CRC_TABLE[13] <= 32'h17;
  CRC_TABLE[14] <= 32'h12;
  CRC_TABLE[15] <= 32'h11;

  CRC_TABLE[16] <= 32'h30;
  CRC_TABLE[17] <= 32'h33;
  CRC_TABLE[18] <= 32'h36;
  CRC_TABLE[19] <= 32'h35;
  CRC_TABLE[20] <= 32'h3c;
  CRC_TABLE[21] <= 32'h3f;
  CRC_TABLE[22] <= 32'h3a;
  CRC_TABLE[23] <= 32'h39;

  CRC_TABLE[24] <= 32'h28;
  CRC_TABLE[25] <= 32'h2b;
  CRC_TABLE[26] <= 32'h2e;
  CRC_TABLE[27] <= 32'h2d;
  CRC_TABLE[28] <= 32'h24;
  CRC_TABLE[29] <= 32'h27;
  CRC_TABLE[30] <= 32'h22;
  CRC_TABLE[31] <= 32'h21;

  CRC_TABLE[32] <= 32'h23;
  CRC_TABLE[33] <= 32'h20;
  CRC_TABLE[34] <= 32'h25;
  CRC_TABLE[35] <= 32'h26;
  CRC_TABLE[36] <= 32'h2f;
  CRC_TABLE[37] <= 32'h2c;
  CRC_TABLE[38] <= 32'h29;
  CRC_TABLE[39] <= 32'h2a;

  CRC_TABLE[40] <= 32'h3b;
  CRC_TABLE[41] <= 32'h38;
  CRC_TABLE[42] <= 32'h3d;
  CRC_TABLE[43] <= 32'h3e;
  CRC_TABLE[44] <= 32'h37;
  CRC_TABLE[45] <= 32'h34;
  CRC_TABLE[46] <= 32'h31;
  CRC_TABLE[47] <= 32'h32;

  CRC_TABLE[48] <= 32'h13;
  CRC_TABLE[49] <= 32'h10;
  CRC_TABLE[50] <= 32'h15;
  CRC_TABLE[51] <= 32'h16;
  CRC_TABLE[52] <= 32'h1f;
  CRC_TABLE[53] <= 32'h1c;
  CRC_TABLE[54] <= 32'h19;
  CRC_TABLE[55] <= 32'h1a;

  CRC_TABLE[56] <= 32'h0b;
  CRC_TABLE[57] <= 32'h08;
  CRC_TABLE[58] <= 32'h0d;
  CRC_TABLE[59] <= 32'h0e;
  CRC_TABLE[60] <= 32'h07;
  CRC_TABLE[61] <= 32'h04;
  CRC_TABLE[62] <= 32'h01;
  CRC_TABLE[63] <= 32'h02;

end

// CRC校验使能启动计数器，用于控制循环次数

always @(posedge clk or negedge rst_n) begin
  if(~rst_n) begin
    cnt_en <= 8'd0;
  end
  else if(crc_en) begin
    cnt_en <= 8'd1;
  end
  else if (cnt_en >= 8'd1 && cnt_en <= 10)begin
    cnt_en <= cnt_en + 8'd1;
  end
  else begin
    cnt_en <= 8'd0;
  end
end

// 根据时钟计算CRC校验值，模拟C语言的从上至下逻辑
always @(posedge clk or negedge rst_n) begin
  if(~rst_n) begin
    calc_i1 <= 8'd0;
    calc_i2 <= 8'd0;
    calc_i3 <= 8'd0;
    calc_i4 <= 8'd0;
    calc_i5 <= 8'd0;
  end
  else begin
    case(cnt_en)
      1:begin
        calc_i1 <= ((data_in >> 24) & 32'h3f) ^ 32'h0;   //28bit的数据，右移30bit就是0
      end
      3:begin
        calc_i2 <= ((data_in >> 18) & 32'h3f) ^ CRC_TABLE[calc_i1];
      end
      5:begin
        calc_i3 <= ((data_in >> 12) & 32'h3f) ^ CRC_TABLE[calc_i2];
      end
      7:begin
        calc_i4 <= ((data_in >> 6)  & 32'h3f) ^ CRC_TABLE[calc_i3];
      end
      9:begin
        calc_i5 <= (      data_in   & 32'h3f) ^ CRC_TABLE[calc_i4];
      end
      default:begin
        calc_i1 <= calc_i1;
        calc_i2 <= calc_i2;
        calc_i3 <= calc_i3;
        calc_i4 <= calc_i4;
        calc_i5 <= calc_i5;
      end
    endcase
  end
end


always @(posedge clk) begin  // CRC校验值输出
  calc_crc <= CRC_TABLE[calc_i5];
end


endmodule
