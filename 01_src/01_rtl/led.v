
`timescale 1 ns / 10 ps
//////////////////////////////////////////////////////////////////////////////////
// Company: DMT
// Engineer: V
// Create Date: 2024/12/17 10:03
// Design Name: led
// Module Name: led
// Project Name: demo_1st_top
// Target Devices: Control Board V3
// Tool Versions: TD 5.6.2
// Description: led
// Dependencies: demo_1st_top
// Revision:1.0
// Revision 1.01 - File Created
// Additional Comments:
//////////////////////////////////////////////////////////////////////////////////
module led(
  input          clk,      // sys clock
  input          rst_n,    // sys reset
    output [3:0] led       // led
);
// reg define
reg  [3:0] led_reg;    // led register
reg [27:0] timer;      // timer
// assign define
assign led = led_reg;
//////////////////////////////////////////////////////////////////////////////////
//                         time counter module
//////////////////////////////////////////////////////////////////////////////////
always @(posedge clk or negedge rst_n) begin
  if (~rst_n) begin
    timer <= 28'd0;
  end
// 4 seconds count(50M*4-1=199999999)
  else if ( timer == 28'd199_999_999 ) begin
    timer <= 28'd0;
  end
  else begin
    timer <= timer + 1'b1;
  end
end
//////////////////////////////////////////////////////////////////////////////////
//                         LED control module
//////////////////////////////////////////////////////////////////////////////////
always @(posedge clk or negedge rst_n) begin
  if (~rst_n) begin
    led_reg <= 4'b1111;
  end
// time counter count to 1st sec,LED1 lighten
  else if( timer == 28'd49_999_999 ) begin
    led_reg <= 4'b1110;
  end
// time counter count to 2nd sec,LED2 lighten
  else if( timer == 28'd99_999_999 ) begin
    led_reg <= 4'b1101;
  end
// time counter count to 3nd sec,LED3 lighten
  else if ( timer == 28'd149_999_999 ) begin
    led_reg <= 4'b1011;
  end
// time counter count to 4nd sec,LED4 lighten
  else if ( timer == 28'd199_999_999 ) begin
    led_reg <= 4'b0111;
  end          
end

endmodule
