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
    input clk,          //ϵͳʱ��
    input rst_n,        //��λ
    input rxd,    //MISO
    inout rx_done,      //�����������
    inout [7 : 0] w_data,//����
    output  txd         //MOSI
    );
    
    uart_rx  my_uart_rx
    (
        .i_clk_sys(clk),        //ϵͳʱ��
        .i_rst_n(rst_n),        //ȫ���첽��λ,�͵�ƽ��Ч
        .i_uart_rx(rxd),  //UART����
        .o_uart_data(w_data),   //UART��������
        .o_rx_done(rx_done)     //UART���ݽ�����ɱ�־
    );
    uart_tx  u_uart_tx
    (   .i_clk_sys(clk),        //ϵͳʱ��
        .i_rst_n(rst_n),        //ȫ���첽��λ
        .i_data_tx(w_data),     //������������
        .i_data_valid(rx_done), //����������Ч
        .o_uart_tx(txd)         //UART���
     );
endmodule