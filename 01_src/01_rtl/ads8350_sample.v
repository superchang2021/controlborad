
`timescale 1 ns / 10 ps
//////////////////////////////////////////////////////////////////////////////////
// Company: DMT
// Engineer: V
// Create Date: 2024/12/19 09:57
// Design Name: ads8350_sample
// Module Name: ads8350_sample
// Project Name: demo_1st_top
// Target Devices: Control Board V3
// Tool Versions: TD 5.6.2
// Description: encoder data decoding top module
// Dependencies: sin_control
// Revision:1.0
// Revision 1.01 - File Created
// Additional Comments: ADC sample using spi protocol
//////////////////////////////////////////////////////////////////////////////////
module ads8350_sample(
// sys interface
  input clk,                     // 200MHz clock
  input rst_n,                   // sys reset
// control interface
  input key,                     // start sample
// ADC interface
  input sdo_a,                   // ADC data a
  input sdo_b,                   // ADC data b
// output interface
    output sclk,                 // ADC clock
    output cs_n,                 // ADC enable
    output conv_done,
    output [15:0] data_a_out,    // ADC data a
    output [15:0] data_b_out     // ADC data b
);
// parameter define
// parameter CLOCK_FREQ = 28'd200_000_000;    // 100MHz sysclk
// parameter  SCLK_FREQ = 26'd20_000_000;     // 20MHz scl
parameter DIV_CNT_MAX = 4'd4;              // CLOCK_FREQ /( SCLK_FREQ * 2) -1;
// reg define
reg        sclk_reg;         // sclk reg
reg        cs_n_reg;         // ADC enable reg
reg        conv_done_reg;    // adc conversion done
reg        conv_en;          // conversion enable
reg  [7:0] LSM_CNT;          // sclk cnt
reg  [7:0] DIV_CNT;          // sys_clk cnt
reg [15:0] data_a;           // data a reg when processing
reg [15:0] data_b;           // data b reg when processing
reg [15:0] data_a_reg;       // data a reg done
reg [15:0] data_b_reg;       // data b reg done
// assign define
assign       sclk = sclk_reg;
assign       cs_n = cs_n_reg;
assign data_a_out = data_a_reg;
assign data_b_out = data_b_reg;
assign  conv_done = conv_done_reg;
//////////////////////////////////////////////////////////////////////////////////
//                             conv_en generate 
//////////////////////////////////////////////////////////////////////////////////
always @(posedge clk or negedge rst_n)begin
  if(~rst_n)begin
    conv_en <= 1'b0;
  end
  else if(key) begin
    conv_en <= 1'b1;
  end
// when DIV_CNT == DIV_CNT_MAX, reset conv_en
  else if( (LSM_CNT == 8'd62) && (DIV_CNT == DIV_CNT_MAX-1'b1) )begin
    conv_en <= 1'b0;
  end
  else begin
    conv_en <= conv_en;
  end
end
//////////////////////////////////////////////////////////////////////////////////
//                             DIV_CNT generate 
//////////////////////////////////////////////////////////////////////////////////
always @(posedge clk or negedge rst_n)begin
  if(~rst_n)begin
    DIV_CNT <= 8'd0;
  end
// when DIV_CNT == DIV_CNT_MAX, reset DIV_CNT
  else if(conv_en)begin
    if(DIV_CNT == DIV_CNT_MAX)begin
        DIV_CNT <= 8'd0;
    end
    else begin
        DIV_CNT <= DIV_CNT + 1'b1;
    end
  end
  else begin
    DIV_CNT <= 8'd0;
  end
end
//////////////////////////////////////////////////////////////////////////////////
//                             LSM_CNT generate 
//////////////////////////////////////////////////////////////////////////////////
always @(posedge clk or negedge rst_n)begin
  if(~rst_n)begin
    LSM_CNT <= 8'd0;
  end
  else if(DIV_CNT == DIV_CNT_MAX)begin
    if(LSM_CNT == 8'd62)begin
        LSM_CNT <= 8'd0;
    end
    else begin
        LSM_CNT <= LSM_CNT + 1'b1;
    end
  end
end
//////////////////////////////////////////////////////////////////////////////////
//                             state output generate 
//////////////////////////////////////////////////////////////////////////////////
always @(posedge clk or negedge rst_n)begin
  if(~rst_n)begin
    data_a   <= 16'd0;
    data_b   <= 16'd0;
    sclk_reg <= 1'b0;
    cs_n_reg <= 1'b1;
  end
  else if(DIV_CNT == DIV_CNT_MAX)begin
    case(LSM_CNT)
// start conv
      8'd0 : begin
        sclk_reg <= 1'b1;
        cs_n_reg <= 1'b0;
      end
// adc conv time
      8'd1 : sclk_reg <= 1'b0;
      8'd2 : sclk_reg <= 1'b1;
      8'd3 : sclk_reg <= 1'b0;
      8'd4 : sclk_reg <= 1'b1;
      8'd5 : sclk_reg <= 1'b0;
      8'd6 : sclk_reg <= 1'b1;
      8'd7 : sclk_reg <= 1'b0;
      8'd8 : sclk_reg <= 1'b1;
      8'd9 : sclk_reg <= 1'b0;
      8'd10: sclk_reg <= 1'b1;
      8'd11: sclk_reg <= 1'b0;
      8'd12: sclk_reg <= 1'b1;
      8'd13: sclk_reg <= 1'b0;
      8'd14: sclk_reg <= 1'b1;
      8'd15: sclk_reg <= 1'b0;
      8'd16: sclk_reg <= 1'b1;
      8'd17: sclk_reg <= 1'b0;
      8'd18: sclk_reg <= 1'b1;
      8'd19: sclk_reg <= 1'b0;
      8'd20: sclk_reg <= 1'b1;
      8'd21: sclk_reg <= 1'b0;
      8'd22: sclk_reg <= 1'b1;
      8'd23: sclk_reg <= 1'b0;
      8'd24: sclk_reg <= 1'b1;
      8'd25: sclk_reg <= 1'b0;
      8'd26: sclk_reg <= 1'b1;
      8'd27: sclk_reg <= 1'b0;
      8'd28: sclk_reg <= 1'b1;
      8'd29: sclk_reg <= 1'b0;
// adc output start
      8'd30:begin
        sclk_reg <= 1'b1;
        data_a[15] <= sdo_a;
        data_b[15] <= sdo_b;
      end
      8'd31: sclk_reg <= 1'b0;
      8'd32:begin
        sclk_reg <= 1'b1;
        data_a[14] <= sdo_a;
        data_b[14] <= sdo_b;
      end
      8'd33: sclk_reg <= 1'b0;
      8'd34:begin
        sclk_reg <= 1'b1;
        data_a[13] <= sdo_a;
        data_b[13] <= sdo_b;
      end
      8'd35: sclk_reg <= 1'b0;
      8'd36:begin
        sclk_reg <= 1'b1;
        data_a[12] <= sdo_a;
        data_b[12] <= sdo_b;
      end
      8'd37: sclk_reg <= 1'b0;
      8'd38:begin
        sclk_reg <= 1'b1;
        data_a[11] <= sdo_a;
        data_b[11] <= sdo_b;
      end
      8'd39: sclk_reg <= 1'b0;
      8'd40:begin
        sclk_reg <= 1'b1;
        data_a[10] <= sdo_a;
        data_b[10] <= sdo_b;
      end
      8'd41: sclk_reg <= 1'b0;
      8'd42:begin
        sclk_reg <= 1'b1;
        data_a[9] <= sdo_a;
        data_b[9] <= sdo_b;
      end
      8'd43: sclk_reg <= 1'b0;
      8'd44:begin
        sclk_reg <= 1'b1;
        data_a[8] <= sdo_a;
        data_b[8] <= sdo_b;
      end
      8'd45: sclk_reg <= 1'b0;
      8'd46:begin
        sclk_reg <= 1'b1;
        data_a[7] <= sdo_a;
        data_b[7] <= sdo_b;
      end
      8'd47: sclk_reg <= 1'b0;
      8'd48:begin
        sclk_reg <= 1'b1;
        data_a[6] <= sdo_a;
        data_b[6] <= sdo_b;
      end
      8'd49: sclk_reg <= 1'b0;
      8'd50:begin
        sclk_reg <= 1'b1;
        data_a[5] <= sdo_a;
        data_b[5] <= sdo_b;
      end
      8'd51: sclk_reg <= 1'b0;
      8'd52:begin
        sclk_reg <= 1'b1;
        data_a[4] <= sdo_a;
        data_b[4] <= sdo_b;
      end
      8'd53: sclk_reg <= 1'b0;
      8'd54:begin
        sclk_reg <= 1'b1;
        data_a[3] <= sdo_a;
        data_b[3] <= sdo_b;
      end
      8'd55: sclk_reg <= 1'b0;
      8'd56:begin
        sclk_reg <= 1'b1;
        data_a[2] <= sdo_a;
        data_b[2] <= sdo_b;
      end
      8'd57: sclk_reg <= 1'b0;
      8'd58:begin
        sclk_reg <= 1'b1;
        data_a[1] <= sdo_a;
        data_b[1] <= sdo_b;
      end
      8'd59: sclk_reg <= 1'b0;
// adc output end
      8'd60:begin
        sclk_reg <= 1'b1;
        data_a[0] <= sdo_a;
        data_b[0] <= sdo_b;
      end
      8'd61: sclk_reg <= 1'b0;
// adc smaple done
      8'd62: begin
        cs_n_reg <=1'b1;
        sclk_reg <= 1'b1;
      end
      default:begin
        cs_n_reg <= 1'b1;
        sclk_reg <= 1'b1;
      end
    endcase
  end
  else begin
    data_a <= data_a;
    data_b <= data_b;
    sclk_reg <= sclk_reg;
    cs_n_reg <= cs_n_reg;
  end
end
//////////////////////////////////////////////////////////////////////////////////
//                             smpale done output data 
//////////////////////////////////////////////////////////////////////////////////
always @(posedge clk or negedge rst_n)begin
  if(~rst_n)begin
    conv_done_reg <= 1'b0;
    data_a_reg <= 16'd0;
    data_b_reg <= 16'd0;
  end
  else if( (LSM_CNT == 8'd62) && (DIV_CNT ==DIV_CNT_MAX) )begin
    conv_done_reg <= 1'b1;
    data_a_reg <= data_a;
    data_b_reg <= data_b;
  end
  else begin
    conv_done_reg <= 1'b0;
    data_a_reg <= data_a_reg;
    data_b_reg <= data_b_reg;
  end
end

endmodule
