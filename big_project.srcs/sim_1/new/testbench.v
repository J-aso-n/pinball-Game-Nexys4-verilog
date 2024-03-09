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
    reg   sys_clk ; //输入工作时钟,频率50MHz     
    reg   rst_n ;  //输入复位信号,低电平有效
    wire  hsync ;  //输出行同步信号 
    wire  vsync ;  //输出场同步信号 
    wire  [11:0]  rgb;  //输出像素信息
    main uut(
        .sys_clk(sys_clk),
        .rst_n(rst_n),
        .hsync(hsync),
        .vsync(vsync),
        .rgb(rgb)
    );
    always//时钟
    begin
        #1 sys_clk=1;
        #1 sys_clk=0;
    end
    initial
    begin 
        rst_n=0;//清零
        sys_clk=0;
        #50 rst_n=1;
    end
endmodule
