`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2023/02/13 10:35:36
// Design Name: 
// Module Name: uart_rx
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


module uart_rx
(
    input                           i_clk_sys,      //系统时钟
    input                           i_rst_n,        //全局异步复位,低电平有效
    input                           i_uart_rx,      //UART输入
    output   reg    [7 :0]          o_uart_data,    //UART接收数据
    output   reg                    o_rx_done       //UART数据接收完成标志
    );
    parameter CLK_FRE = 100;         //时钟频率，默认时钟频率为100MHz
    parameter DATA_WIDTH = 8;
    parameter BAUD_RATE = 9600;      //波特率，缺省为9600

    /*
    连续采样五个接收路电平来判断rx是否有信号传来
    用五个采样信号来作为判断标准可以有效排除毛刺噪声带来的误判
    */
    reg [4:0] r_flag_rcv_start;
    always@(posedge i_clk_sys or negedge i_rst_n)
        begin
            if(!i_rst_n)
                r_flag_rcv_start <= 5'b11111;
            else
                r_flag_rcv_start <= {r_flag_rcv_start[3:0], i_uart_rx};
        end

    //状态机定义
    reg [2:0] r_current_state;  //当前状态
    reg [2:0] r_next_state;     //次态
        
    localparam STATE_IDLE = 3'b000;         //空闲状态
    localparam STATE_START = 3'b001;        //开始状态
    localparam STATE_DATA = 3'b011;         //数据接收状态
    localparam STATE_END = 3'b100;          //结束状态
        
    localparam CYCLE = CLK_FRE * 1000000 / BAUD_RATE;   //波特计数周期
    
    reg baud_valid;       //波特计数有效位
    reg [15:0] baud_cnt;  //波特率计数器 
    reg baud_pulse;       //波特率采样脉冲
     
    //波特率计数器
    always@(posedge i_clk_sys or negedge i_rst_n)
        begin
            if(!i_rst_n)
                baud_cnt <= 16'h0000;
            else if(!baud_valid)
                baud_cnt <= 16'h0000;
            else if(baud_cnt == CYCLE - 1)
                baud_cnt <= 16'h0000;
            else
                baud_cnt <= baud_cnt + 1'b1;
        end
        
    //波特采样脉冲
    always@(posedge i_clk_sys or negedge i_rst_n)
        begin
            if(!i_rst_n)
                baud_pulse <= 1'b0;
            else if(baud_cnt == CYCLE/2-1)
                baud_pulse <= 1'b1;
            else
                baud_pulse <= 1'b0;
        end
    
    //状态机状态变化定义
    always@(posedge i_clk_sys or negedge i_rst_n)
        begin
            if(!i_rst_n)
                r_current_state <= STATE_IDLE;
            else if(!baud_valid)
                r_current_state <= STATE_IDLE;
            else if(baud_valid && baud_cnt == 16'h0000) //一个波特率周期才变化一次
                r_current_state <= r_next_state;
        end
        
    reg [3:0]   r_rcv_cnt;      //接收数据位计数
    //状态机次态定义
    always@(*)
        begin
            case(r_current_state)
                STATE_IDLE:     r_next_state <= STATE_START;
                STATE_START:    r_next_state <= STATE_DATA;
                STATE_DATA:
                    if(r_rcv_cnt == DATA_WIDTH)
                          r_next_state <= STATE_END;
                    else
                    begin
                          r_next_state <= STATE_DATA;
                    end
                STATE_END:      r_next_state <= STATE_IDLE;
                default:;
            endcase
        end

    reg [DATA_WIDTH - 1 :0] r_data_rcv; //接收的数据
    
    //状态机输出逻辑
    always@(posedge i_clk_sys or negedge i_rst_n)
        begin
            if(!i_rst_n)
                begin
                    baud_valid <= 1'b0;
                    r_data_rcv <= 'd0;
                    r_rcv_cnt <= 4'd0;
                    o_uart_data <= 'd0;
                    o_rx_done <= 1'b0;
                end
            else
                case(r_current_state)
                    STATE_IDLE:begin
                        //闲置状态下对寄存器进行复位
                        r_rcv_cnt <= 4'd0;
                        r_data_rcv <= 'd0;
                        o_rx_done <= 1'b0;
                        //连续检测到低电平时认为UART传来数据，拉高baud_valid
                        if(r_flag_rcv_start == 5'b00000)
                            baud_valid <= 1'b1;
                    end
                    STATE_START:begin
                        if(baud_pulse && i_uart_rx)//波特率采样脉冲到来时再次检测是否为低电平，如果不为低电平，认为前期误检测，重新进入IDLE状态
                            baud_valid <= 1'b0;
                    end
                    STATE_DATA:begin
                        if(baud_pulse)
                            begin
                                r_data_rcv <= {i_uart_rx, r_data_rcv[DATA_WIDTH-1 : 1]}; //数据移位存储
                                r_rcv_cnt <= r_rcv_cnt + 1'b1;                          //数据位计数
                            end
                    end
                    STATE_END:begin
                        if(baud_pulse)
                            begin
                            //没有校验位或者校验位正确时才输出数据，否则直接丢弃数据
                                o_uart_data <= r_data_rcv;
                                o_rx_done <= 1'b1; //输入完成信号
                            end
                        else
                            begin
                                o_rx_done <= 1'b0;
                            end
                            
                        if(baud_cnt == 16'h0000)
                             baud_valid <= 1'b0;
                        end
                    default:;
                endcase
        end
    
    
endmodule


