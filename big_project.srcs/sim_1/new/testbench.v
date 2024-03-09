`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2023/01/31 23:36:54
// Design Name: 
// Module Name: testbench
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


module testbench(

    );
    reg   sys_clk ; //���빤��ʱ��,Ƶ��50MHz     
    reg   rst_n ;  //���븴λ�ź�,�͵�ƽ��Ч
    wire  hsync ;  //�����ͬ���ź� 
    wire  vsync ;  //�����ͬ���ź� 
    wire  [11:0]  rgb;  //���������Ϣ
    main uut(
        .sys_clk(sys_clk),
        .rst_n(rst_n),
        .hsync(hsync),
        .vsync(vsync),
        .rgb(rgb)
    );
    always//ʱ��
    begin
        #1 sys_clk=1;
        #1 sys_clk=0;
    end
    initial
    begin 
        rst_n=0;//����
        sys_clk=0;
        #50 rst_n=1;
    end
endmodule
