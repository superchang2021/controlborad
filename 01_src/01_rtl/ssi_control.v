
`timescale 1 ns / 10 ps
//////////////////////////////////////////////////////////////////////////////////
// Company: DMT
// Engineer: V
// Create Date: 2024/12/18 13:29
// Design Name: ssi_control
// Module Name: ssi_control
// Project Name: demo_1st_top
// Target Devices: Control Board V3
// Tool Versions: TD 5.6.2
// Description: encoder data decoding top module
// Dependencies: encoder_control
// Revision:1.0
// Revision 1.01 - File Created
// Additional Comments:
//////////////////////////////////////////////////////////////////////////////////
module ssi_control(
  input    clk,                 // 200MHz clk
  input    rst_n,               // reset
  input    key,                 // data request
  input    data_in,             // ssi data input
    output clk_out,             // ssi clk output
    output [31:0] data_out      // ssi angle data output
);
// parameter define  
parameter     IDLE = 3'b001;    // state define
parameter     DATA = 3'b010;    // state define
parameter     STOP = 3'b100;    // state define
parameter  CNT_PLL = 8'd49;     // 2 MHz cnt in 200MHz
parameter CNT_STOP = 8'd52;     // 26.5us cnt in 2MHz
// wire define
wire       IDLE2DATA_start;     // state shift condition
wire       ATA2STOP_start;      // state shift condition
wire       STOP2IDLE_start;     // state shift condition
wire       clk_out_rev;         // biss clk out reverse
// reg define
reg  [2:0] state_c;             // state current
reg  [2:0] state_n;             // state next
reg        flag_DATA;           // state shift flag
reg        flag_STOP;           // state shift flag
reg        flag_IDLE;           // state shift flag
reg [11:0] cnt_clk;             // clk 2M cnt to timer
reg        clk_2M;              // 2M clk
reg        cnt_2M_reg0;         // 2m clk reg
reg        cnt_2M_reg1;         // 2m clk reg
reg        pose_clk_2MHz;       // 2MHz clk first pos
reg        request;             // ssi start flag
reg        clk_out_reg;         // ssi clk out
reg        clk_out_reg0;        // ssi clk out reg
reg        clk_out_reg1;        // ssi clk out reg
reg        clk_out_reg_pose;    // ssi clk out reg pose
reg [31:0] cnt_pose;            // clk out cnt pose 
reg [31:0] cnt_pose_down;       // clk out cnt pose down
reg        data_in_reg0;        // data in reg
reg        data_in_reg1;        // data in reg
reg  [7:0] cnt_data_down;       // data input cnt
reg        read_done;           // ssi data read done
reg [22:0] angle;               // ssi data in reg
reg [22:0] angle_reg;           // ssi angle data output reg
reg  [7:0] DATA_cntclk;         // clk pose egde cnt at DATA state
reg  [7:0] DATA_cntclkdown;     // clk nege egde cnt at DATA state
reg  [7:0] STOP_cntclk;         // clk pose egde cnt at STOP state
// assign define
assign IDLE2DATA_start = (state_c == IDLE) && flag_DATA;
assign DATA2STOP_start = (state_c == DATA) && flag_STOP;
assign STOP2IDLE_start = (state_c == STOP) && flag_IDLE;
assign        data_out = angle_reg;
assign         clk_out = clk_out_reg;
assign     clk_out_rev = ~clk_out_reg1;
//////////////////////////////////////////////////////////////////////////////////
//                                2MHz generator
//////////////////////////////////////////////////////////////////////////////////
always @(posedge clk or negedge rst_n) begin
  if(~rst_n) begin
    clk_2M  <= 1'b1;
    cnt_clk <= 12'd0;
  end
  else if(cnt_clk == CNT_PLL) begin
    clk_2M  <= ~clk_2M;
    cnt_clk <= 12'd0;
  end
  else begin
    clk_2M  <= clk_2M;
    cnt_clk <= cnt_clk + 1'b1;
  end
end
//////////////////////////////////////////////////////////////////////////////////
//                             encoder data request
//////////////////////////////////////////////////////////////////////////////////
always @(posedge clk or negedge rst_n) begin
  if(~rst_n) begin
    request <= 1'b0;
  end
// data request set by key
  else if(key) begin
    request <= 1'b1;
  end
  else if(flag_STOP) begin
    request <= 1'b0;
  end
  else begin
    request <= request;
  end
end
//////////////////////////////////////////////////////////////////////////////////
//                      2MHz\5MHz\biss_clk\biss_data latch
//////////////////////////////////////////////////////////////////////////////////
always @(posedge clk or negedge rst_n) begin
  if(~rst_n) begin
    cnt_2M_reg0  <= 1'b1;
    cnt_2M_reg1  <= 1'b1;
    clk_out_reg0 <= 1'b1;
    clk_out_reg1 <= 1'b1;
    data_in_reg0 <= 1'b1;
    data_in_reg1 <= 1'b1;
  end
  else begin
    cnt_2M_reg0  <= clk_2M;
    cnt_2M_reg1  <= cnt_2M_reg0;
    clk_out_reg0 <= clk_out_reg;
    clk_out_reg1 <= clk_out_reg0;
    data_in_reg0 <= data_in;
    data_in_reg1 <= data_in_reg0;
  end
end
//////////////////////////////////////////////////////////////////////////////////
//                              SSI clk output
//////////////////////////////////////////////////////////////////////////////////
always @(posedge clk or negedge rst_n) begin
  if(~rst_n) begin
    pose_clk_2MHz <= 1'b0;
  end
// at the first rising edge of clk_2MHz,set pose_clk_2MHz high
  else if({request,cnt_2M_reg0,cnt_2M_reg1} == 3'b110) begin
    pose_clk_2MHz <= 1'b1;
  end
  else if(flag_STOP) begin
    pose_clk_2MHz <= 1'b0;
  end
  else begin
    pose_clk_2MHz <= pose_clk_2MHz;
  end
end
always @(posedge clk or negedge rst_n) begin
  if(~rst_n) begin
    clk_out_reg <= 1'b1;
  end
// IDLE state,set clk_out_reg high
  else if(flag_IDLE) begin
    clk_out_reg <= 1'b1;
  end
  else if(pose_clk_2MHz) begin
    clk_out_reg <= clk_2M;
  end
  else begin
    clk_out_reg <= 1'b1;
  end
end
//////////////////////////////////////////////////////////////////////////////////
//                        catch clk out posedge/negedge
//////////////////////////////////////////////////////////////////////////////////
always @(posedge clk or negedge rst_n) begin
  if(~rst_n) begin
    clk_out_reg_pose <= 1'b0;
    cnt_pose         <= 32'd0;
    cnt_pose_down    <= 32'd0;
    cnt_data_down    <= 32'd0;
  end
  else if(flag_IDLE) begin
    clk_out_reg_pose <= 1'b0;
    cnt_pose         <= 32'd0;
    cnt_pose_down    <= 32'd0;
    cnt_data_down    <= 32'd0;
  end
  else if ({data_in_reg0,data_in_reg1} == 2'b01) begin
    cnt_data_down    <= cnt_data_down + 1'b1;
  end
  else if({clk_out_reg0,clk_out_reg1} == 2'b10) begin
    clk_out_reg_pose <= 1'b1;
    cnt_pose         <= cnt_pose + 1'b1;
  end
  else if({clk_out_reg0,clk_out_reg1} == 2'b01) begin
    cnt_pose_down    <= cnt_pose_down + 1'b1;
  end
  else begin
    clk_out_reg_pose <= 1'b0;
    cnt_pose         <= cnt_pose;
    cnt_pose_down    <= cnt_pose_down;
    cnt_data_down    <= cnt_data_down;
  end
end
//////////////////////////////////////////////////////////////////////////////////
//                              state flag generator
//////////////////////////////////////////////////////////////////////////////////
always @(posedge clk or negedge rst_n) begin
  if(~rst_n) begin
    flag_DATA <= 1'b0;
    flag_STOP <= 1'b0;
  end
// data input 1 negative edge were data state begin
  else if(({data_in_reg0,data_in_reg1} == 2'b01) && (cnt_data_down == 8'd0)) begin
    flag_DATA <= 1'b1;
  end
// clk output N+1 pose edge were stop state begin
  else if((state_c == DATA) && (DATA_cntclk == 8'd23)) begin
    flag_STOP <= 1'b1;
  end
  else begin
    flag_DATA <= 1'b0;
    flag_STOP <= 1'b0;
  end
end
always @(posedge clk or negedge rst_n) begin
  if(~rst_n) begin
    flag_IDLE <= 1'b0;
  end
// when 26us after stop state, go to idle state
  else if(STOP_cntclk == CNT_STOP) begin
    flag_IDLE <= 1'b1;
  end
  else begin
    flag_IDLE <= 1'b0;
  end
end
//////////////////////////////////////////////////////////////////////////////////
//                              sync always block
//////////////////////////////////////////////////////////////////////////////////
always @(posedge clk or negedge rst_n) begin
  if(~rst_n) begin
    state_c <= IDLE;
  end
  else begin
    state_c <= state_n;
  end
end
//////////////////////////////////////////////////////////////////////////////////
//                           combinational logic block
//////////////////////////////////////////////////////////////////////////////////
always @(*) begin
  case(state_c)
    IDLE:begin
      if(IDLE2DATA_start) begin
        state_n <= DATA;
      end
      else begin
        state_n <= state_c;
      end
    end
    DATA:begin
      if(DATA2STOP_start) begin
        state_n <= STOP;
      end
      else begin
        state_n <= state_c;
      end
    end
    STOP:begin
      if(STOP2IDLE_start) begin
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
//////////////////////////////////////////////////////////////////////////////////
//                         state machine output data
//////////////////////////////////////////////////////////////////////////////////
always @(posedge clk or negedge rst_n) begin
  if(~rst_n) begin
    DATA_cntclk     <= 32'd0;
    DATA_cntclkdown <= 32'd0;
  end
  else if(flag_IDLE) begin
    DATA_cntclk <= 32'd0;
    DATA_cntclkdown <= 32'd0;
  end
  else if (state_c == DATA && clk_out_reg_pose)begin
    DATA_cntclk     <= DATA_cntclk + 1'b1;
  end
  else if(state_c == DATA && ({clk_out_reg0,clk_out_reg1} == 2'b01)) begin
    DATA_cntclkdown <= DATA_cntclkdown + 1'b1;
  end
  else begin
    DATA_cntclk     <= DATA_cntclk;
    DATA_cntclkdown <= DATA_cntclkdown;
  end
end
always @(posedge clk_out_rev or negedge rst_n) begin
  if(~rst_n) begin
    angle     <= 16'd0;
    read_done <= 1'b0;
  end
// DATA state,save the data using DATA_cntclk
  else if (state_c == DATA) begin
    case(DATA_cntclk)
      1:begin
        angle[22] <= data_in_reg1;
      end
      2:begin
        angle[21] <= data_in_reg1;
      end
      3:begin
        angle[20] <= data_in_reg1;
      end
      4:begin
        angle[19] <= data_in_reg1;
      end
      5:begin
        angle[18] <= data_in_reg1;
      end
      6:begin
        angle[17] <= data_in_reg1;
      end
      7:begin
        angle[16] <= data_in_reg1;
      end
      8:begin
        angle[15] <= data_in_reg1;
      end
      9:begin
        angle[14] <= data_in_reg1;
      end
      10:begin
        angle[13] <= data_in_reg1;
      end
      11:begin
        angle[12] <= data_in_reg1;
      end
      12:begin
        angle[11] <= data_in_reg1;
      end
      13:begin
        angle[10] <= data_in_reg1;
      end
      14:begin
        angle[9]  <= data_in_reg1;
      end
      15:begin
        angle[8]  <= data_in_reg1;
      end
      16:begin
        angle[7]  <= data_in_reg1;
      end
      17:begin
        angle[6]  <= data_in_reg1;
      end
      18:begin
        angle[5]  <= data_in_reg1;
      end
      19:begin
        angle[4]  <= data_in_reg1;
      end
      20:begin
        angle[3]  <= data_in_reg1;
      end
      21:begin
        angle[2]  <= data_in_reg1;
      end
      22:begin
        angle[1]  <= data_in_reg1;
      end
      23:begin
        angle[0]  <= data_in_reg1;
        read_done <= 1'b1;
      end
      default:begin
        angle     <= angle;
        read_done <= 1'b0;
      end
    endcase
  end
  else begin
    angle     <= angle;
    read_done <= 1'b0;
  end
end
//////////////////////////////////////////////////////////////////////////////////
//                             STOP state  cnter
//////////////////////////////////////////////////////////////////////////////////
always @(posedge clk_2M or negedge rst_n) begin
  if(~rst_n) begin
    STOP_cntclk <= 32'd0;
  end
  else if(flag_IDLE) begin
    STOP_cntclk <= 32'd0;
  end
// cnt 26us using 2MHz clk
  else if(state_c == STOP)begin
    STOP_cntclk <= STOP_cntclk + 1'b1;
  end
  else begin
    STOP_cntclk <= STOP_cntclk;
  end
end
//////////////////////////////////////////////////////////////////////////////////
//                             SSI data output 
//////////////////////////////////////////////////////////////////////////////////
always @(posedge clk or negedge rst_n) begin
  if(~rst_n) begin
    angle_reg <= 23'd0;
  end
  else if(read_done) begin
    angle_reg <= angle;
  end
  else begin
    angle_reg <= angle_reg;
  end
end

endmodule
