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
    input                           i_clk_sys,      //ϵͳʱ��
    input                           i_rst_n,        //ȫ���첽��λ,�͵�ƽ��Ч
    input                           i_uart_rx,      //UART����
    output   reg    [7 :0]          o_uart_data,    //UART��������
    output   reg                    o_rx_done       //UART���ݽ�����ɱ�־
    );
    parameter CLK_FRE = 100;         //ʱ��Ƶ�ʣ�Ĭ��ʱ��Ƶ��Ϊ100MHz
    parameter DATA_WIDTH = 8;
    parameter BAUD_RATE = 9600;      //�����ʣ�ȱʡΪ9600

    /*
    ���������������·��ƽ���ж�rx�Ƿ����źŴ���
    ����������ź�����Ϊ�жϱ�׼������Ч�ų�ë����������������
    */
    reg [4:0] r_flag_rcv_start;
    always@(posedge i_clk_sys or negedge i_rst_n)
        begin
            if(!i_rst_n)
                r_flag_rcv_start <= 5'b11111;
            else
                r_flag_rcv_start <= {r_flag_rcv_start[3:0], i_uart_rx};
        end

    //״̬������
    reg [2:0] r_current_state;  //��ǰ״̬
    reg [2:0] r_next_state;     //��̬
        
    localparam STATE_IDLE = 3'b000;         //����״̬
    localparam STATE_START = 3'b001;        //��ʼ״̬
    localparam STATE_DATA = 3'b011;         //���ݽ���״̬
    localparam STATE_END = 3'b100;          //����״̬
        
    localparam CYCLE = CLK_FRE * 1000000 / BAUD_RATE;   //���ؼ�������
    
    reg baud_valid;       //���ؼ�����Чλ
    reg [15:0] baud_cnt;  //�����ʼ����� 
    reg baud_pulse;       //�����ʲ�������
     
    //�����ʼ�����
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
        
    //���ز�������
    always@(posedge i_clk_sys or negedge i_rst_n)
        begin
            if(!i_rst_n)
                baud_pulse <= 1'b0;
            else if(baud_cnt == CYCLE/2-1)
                baud_pulse <= 1'b1;
            else
                baud_pulse <= 1'b0;
        end
    
    //״̬��״̬�仯����
    always@(posedge i_clk_sys or negedge i_rst_n)
        begin
            if(!i_rst_n)
                r_current_state <= STATE_IDLE;
            else if(!baud_valid)
                r_current_state <= STATE_IDLE;
            else if(baud_valid && baud_cnt == 16'h0000) //һ�����������ڲű仯һ��
                r_current_state <= r_next_state;
        end
        
    reg [3:0]   r_rcv_cnt;      //��������λ����
    //״̬����̬����
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

    reg [DATA_WIDTH - 1 :0] r_data_rcv; //���յ�����
    
    //״̬������߼�
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
                        //����״̬�¶ԼĴ������и�λ
                        r_rcv_cnt <= 4'd0;
                        r_data_rcv <= 'd0;
                        o_rx_done <= 1'b0;
                        //������⵽�͵�ƽʱ��ΪUART�������ݣ�����baud_valid
                        if(r_flag_rcv_start == 5'b00000)
                            baud_valid <= 1'b1;
                    end
                    STATE_START:begin
                        if(baud_pulse && i_uart_rx)//�����ʲ������嵽��ʱ�ٴμ���Ƿ�Ϊ�͵�ƽ�������Ϊ�͵�ƽ����Ϊǰ�����⣬���½���IDLE״̬
                            baud_valid <= 1'b0;
                    end
                    STATE_DATA:begin
                        if(baud_pulse)
                            begin
                                r_data_rcv <= {i_uart_rx, r_data_rcv[DATA_WIDTH-1 : 1]}; //������λ�洢
                                r_rcv_cnt <= r_rcv_cnt + 1'b1;                          //����λ����
                            end
                    end
                    STATE_END:begin
                        if(baud_pulse)
                            begin
                            //û��У��λ����У��λ��ȷʱ��������ݣ�����ֱ�Ӷ�������
                                o_uart_data <= r_data_rcv;
                                o_rx_done <= 1'b1; //��������ź�
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


