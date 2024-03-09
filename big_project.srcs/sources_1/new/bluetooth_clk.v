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

//����ʱ��
module bluetooth_clk(
    input clk,        //100MHz
    input rst_n,      //��λ
    output reg clk_out//���ʱ��
    );
    parameter Baud_Rate=9600; //������
    localparam div_num='d100_000_000/Baud_Rate; //��Ƶ��Ϊʱ�����ʳ��Բ�����, ����Ƶ��100M
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
