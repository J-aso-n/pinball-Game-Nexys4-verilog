`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2023/02/13 23:41:35
// Design Name: 
// Module Name: uart_tx
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


module uart_tx
(   
    input             i_clk_sys,      //ϵͳʱ��
    input             i_rst_n,        //ȫ���첽��λ
    input  [7 : 0]    i_data_tx,      //������������
    input             i_data_valid,   //����������Ч���Ѿ�����ɹ���
    output   reg      o_uart_tx       //UART���
    );
   parameter CLK_FRE = 100;         //ʱ��Ƶ�ʣ�Ĭ��ʱ��Ƶ��Ϊ100MHz
   parameter DATA_WIDTH = 8;       //��Ч����λ��ȱʡΪ8λ
   parameter BAUD_RATE = 9600;      //�����ʣ�ȱʡΪ9600
       
   //״̬������
   reg [2:0] r_current_state;  //��ǰ״̬
   reg [2:0] r_next_state;     //��̬
               
   localparam STATE_IDLE = 3'b000;         //����״̬
   localparam STATE_START = 3'b001;        //��ʼ״̬
   localparam STATE_DATA = 3'b011;         //���ݷ���״̬
   localparam STATE_END = 3'b100;          //����״̬
  
   localparam CYCLE = CLK_FRE * 1000000 / BAUD_RATE;   //���ؼ�������
           
   reg baud_valid;                         //���ؼ�����Чλ
   reg [15:0] baud_cnt;                    //�����ʼ����� 
   reg baud_pulse;                         //�����ʲ�������
           
   reg [3:0]   r_tx_cnt;      //��������λ����
           
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
        else if(baud_valid && baud_cnt == 16'h0000)
             r_current_state <= r_next_state;
     end
           
     //״̬����̬����
     always@(*)
     begin
          case(r_current_state)
              STATE_IDLE:     r_next_state <= STATE_START;
              STATE_START:    r_next_state <= STATE_DATA;
              STATE_DATA:
                  if(r_tx_cnt == DATA_WIDTH)
                       r_next_state <= STATE_END;
                  else
                  begin
                       r_next_state <= STATE_DATA;
                  end
              STATE_END:      r_next_state <= STATE_IDLE;
              default:;
          endcase
      end
   
   reg [DATA_WIDTH-1 : 0]      r_data_tx;

   //״̬������߼�
   always@(posedge i_clk_sys or negedge i_rst_n)
       begin
           if(!i_rst_n)
               begin
                   baud_valid  <= 1'b0;
                   r_data_tx   <= 'd0;
                   o_uart_tx   <= 1'b1;
                   r_tx_cnt    <= 4'd0;
               end
           else
               case(r_current_state)
                   STATE_IDLE:begin
                           o_uart_tx   <= 1'b1;
                           r_tx_cnt    <= 4'd0;
                           if(i_data_valid)
                               begin
                                   baud_valid <= 1'b1;
                                   r_data_tx <= i_data_tx;
                               end
                       end
                   STATE_START:begin
                           if(baud_pulse)
                               o_uart_tx   <= 1'b0;   //���͵�ƽ��ʼ���䣨��ʼλ��
                       end
                   STATE_DATA:begin
                           if(baud_pulse)
                               begin
                                   r_tx_cnt <= r_tx_cnt + 1'b1;
                                   o_uart_tx <= r_data_tx[0];
                                   r_data_tx <= {1'b0 ,r_data_tx[DATA_WIDTH-1:1]};
                               end
                       end
                   STATE_END:begin
                           if(baud_pulse)
                               begin
                                   o_uart_tx <= 1'b1;   //���ߵ�ƽ������
                                   baud_valid <= 1'b0;
                               end
                       end
                   default:;
               endcase
       end

endmodule
