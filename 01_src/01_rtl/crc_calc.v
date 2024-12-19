// 计算CRC校验值

module crc_calc(
  input clk,
  input rst_n,
  input [23:0] angle_data,
  input [7:0] SF_data,
  input [7:0] REQUEST,
  input [7:0] ENID,
  input [7:0] ALMC,
  input [23:0] turn_data,
    output [7:0] crc_calc
);

reg [7:0] crc_reg/*synthesis keep*/;

assign crc_calc = crc_reg;

always @(posedge clk or negedge rst_n) begin
  if(~rst_n) begin
    crc_reg <= 8'd0;
  end
  else begin
    crc_reg[0] <= SF_data[0] ^ angle_data[0] ^ REQUEST[0] ^ angle_data[8]  ^ angle_data[16] ^ ENID[0] ^ ALMC[0] ^ turn_data[0] ^ turn_data[8] ^  turn_data[16];
    crc_reg[1] <= SF_data[1] ^ angle_data[1] ^ REQUEST[1] ^ angle_data[9]  ^ angle_data[17] ^ ENID[1] ^ ALMC[1] ^ turn_data[1] ^ turn_data[9] ^  turn_data[17];
    crc_reg[2] <= SF_data[2] ^ angle_data[2] ^ REQUEST[2] ^ angle_data[10] ^ angle_data[18] ^ ENID[2] ^ ALMC[2] ^ turn_data[2] ^ turn_data[10] ^ turn_data[18];
    crc_reg[3] <= SF_data[3] ^ angle_data[3] ^ REQUEST[3] ^ angle_data[11] ^ angle_data[19] ^ ENID[3] ^ ALMC[3] ^ turn_data[3] ^ turn_data[11] ^ turn_data[19];
    crc_reg[4] <= SF_data[4] ^ angle_data[4] ^ REQUEST[4] ^ angle_data[12] ^ angle_data[20] ^ ENID[4] ^ ALMC[4] ^ turn_data[4] ^ turn_data[12] ^ turn_data[20];
    crc_reg[5] <= SF_data[5] ^ angle_data[5] ^ REQUEST[5] ^ angle_data[13] ^ angle_data[21] ^ ENID[5] ^ ALMC[5] ^ turn_data[5] ^ turn_data[13] ^ turn_data[21];
    crc_reg[6] <= SF_data[6] ^ angle_data[6] ^ REQUEST[6] ^ angle_data[14] ^ angle_data[22] ^ ENID[6] ^ ALMC[6] ^ turn_data[6] ^ turn_data[14] ^ turn_data[22];
    crc_reg[7] <= SF_data[7] ^ angle_data[7] ^ REQUEST[7] ^ angle_data[15] ^ angle_data[23] ^ ENID[7] ^ ALMC[7] ^ turn_data[7] ^ turn_data[15] ^ turn_data[23];
  end
end


endmodule
