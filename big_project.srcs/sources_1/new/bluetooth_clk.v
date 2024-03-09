`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2023/02/13 21:18:11
// Design Name: 
// Module Name: bluetooth_clk
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

//蓝牙时钟
module bluetooth_clk(
    input clk,        //100MHz
    input rst_n,      //复位
    output reg clk_out//输出时钟
    );
    parameter Baud_Rate=9600; //波特率
    localparam div_num='d100_000_000/Baud_Rate; //分频数为时钟速率除以波特率, 板子频率100M
    reg[15:0]num;
        
    always@(posedge clk)
    if(num==div_num)begin
        num<=0;
        clk_out<=1;
     end
     else begin
        num<=num+1;
        clk_out<=0;
     end
endmodule
