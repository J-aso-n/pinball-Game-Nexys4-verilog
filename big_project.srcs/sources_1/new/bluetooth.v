`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2023/02/13 10:31:17
// Design Name: 
// Module Name: bluetooth
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


module bluetooth(
    input clk,          //系统时钟
    input rst_n,        //复位
    input rxd,    //MISO
    inout rx_done,      //蓝牙输入结束
    inout [7 : 0] w_data,//数据
    output  txd         //MOSI
    );
    
    uart_rx  my_uart_rx
    (
        .i_clk_sys(clk),        //系统时钟
        .i_rst_n(rst_n),        //全局异步复位,低电平有效
        .i_uart_rx(rxd),  //UART输入
        .o_uart_data(w_data),   //UART接收数据
        .o_rx_done(rx_done)     //UART数据接收完成标志
    );
    uart_tx  u_uart_tx
    (   .i_clk_sys(clk),        //系统时钟
        .i_rst_n(rst_n),        //全局异步复位
        .i_data_tx(w_data),     //传输数据输入
        .i_data_valid(rx_done), //传输数据有效
        .o_uart_tx(txd)         //UART输出
     );
endmodule