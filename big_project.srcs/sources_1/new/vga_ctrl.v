`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2023/01/31 15:38:34
// Design Name: 
// Module Name: vga_ctrl
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


module vga_ctrl(
    input   vga_clk ,         //���빤��ʱ��,Ƶ��25MHz 
    input   rst_n ,           //��λ�ź�,�͵�ƽ��Ч     
    input   [11:0]  pix_data ,//�������ص�ɫ����Ϣ
    output  [9:0]   pix_x ,   //���VGA��Ч��ʾ�������ص�X������ 
    output  [9:0]   pix_y ,   //���VGA��Ч��ʾ�������ص�Y������ 
    output  hsync ,           //��ͬ���ź� (�ߵ�ƽ��Ч)
    output  vsync ,           //��ͬ���ź�(��) 
    output  [11:0]  rgb ,     //������ص�ɫ����Ϣ
    output  vs                //һ֡�Ƿ����
    );
    
    /*
    parameter H_SYNC    =   10'd1  ,   //��ͬ��ʱ��������           
                  H_BACK    =   10'd0  ,   //��ʱ�����           
                  H_LEFT    =   10'd0   ,   //��ʱ����߿�           
                  H_VALID   =   10'd4 ,   //����Ч����           
                  H_RIGHT   =   10'd5   ,   //��ʱ���ұ߿�           
                  H_FRONT   =   10'd6   ,   //��ʱ��ǰ��           
                  H_TOTAL   =   10'd16 ;   //��ɨ������ 
                  //800=96+40+8+640����Ч��+8+8
        parameter V_SYNC    =   10'd1   ,   //��ͬ��           
                  V_BACK    =   10'd0  ,   //��ʱ�����     
                  V_TOP     =   10'd0   ,   //��ʱ���ϱ߿�       
                  V_VALID   =   10'd4 ,   //����Ч����
                  V_BOTTOM  =   10'd5   ,   //��ʱ���±߿�    
                  V_FRONT   =   10'd6   ,   //��ʱ��ǰ��       
                  V_TOTAL   =   10'd16 ;   //��ɨ������
                  */
    //����1024*768@60��ʾģʽ(1024*768��֡��60)����
    //����640*480@60��ʾģʽ(640*480��֡��60)25MHz
    parameter H_SYNC    =   15'd96  ,   //��ͬ��ʱ��������           
              H_BACK    =   15'd40  ,   //��ʱ�����           
              H_LEFT    =   15'd8   ,   //��ʱ����߿�           
              H_VALID   =   15'd640 ,   //����Ч����           
              H_RIGHT   =   15'd8   ,   //��ʱ���ұ߿�           
              H_FRONT   =   15'd8   ,   //��ʱ��ǰ��           
              H_TOTAL   =   15'd800 ;   //��ɨ������ 
    parameter V_SYNC    =   10'd2   ,   //��ͬ��           
              V_BACK    =   10'd25  ,   //��ʱ�����     
              V_TOP     =   10'd8   ,   //��ʱ���ϱ߿�       
              V_VALID   =   10'd480 ,   //����Ч����
              V_BOTTOM  =   10'd8   ,   //��ʱ���±߿�    
              V_FRONT   =   10'd2   ,   //��ʱ��ǰ��       
              V_TOTAL   =   10'd525 ;   //��ɨ������
              
    wire   rgb_valid       ;   //VGA��Ч��ʾ���� 
    wire   pix_data_req    ;   //���ص�ɫ����Ϣ�����ź�
    reg    [9:0]   cnt_h   ;   //��ͬ���źż����� 
    reg    [9:0]   cnt_v   ;   //��ͬ���źż�����
    
    //cnt_h:��ͬ���źż����� 
    always@(posedge vga_clk or  negedge rst_n)     
    if(rst_n == 0)         
       cnt_h   <=  0;//��λ����������     
    else   if(cnt_h == H_TOTAL - 1'd1)         
       cnt_h   <=  0;//������ĩ����������     
    else  
       cnt_h   <=  cnt_h + 1'd1;//������1
       
    //hsync:��ͬ���ź� 
    assign  hsync = (cnt_h  <=  H_SYNC - 1'd1) ? 1'b1 : 1'b0;
    
    //cnt_v:��ͬ���źż����� 
    always@(posedge vga_clk or  negedge rst_n)     
    if(rst_n == 0)      
    begin
        cnt_v   <=  0;//��λ����������
    end
    else if((cnt_v == V_TOTAL - 1'd1) &&  (cnt_h == H_TOTAL-1'd1))        
    begin
        cnt_v   <=  0;//��������ʾ�����һ��λ�ã���λ    
    end
    else if(cnt_h == H_TOTAL - 1'd1)        
    begin
        cnt_v   <=  cnt_v + 1'd1;//���źŵ��������һ��λ�ã����źż�һ   
    end 
    else       
    begin
        cnt_v   <=  cnt_v;//�����������
    end

    //vsync:��ͬ���ź� 
    assign  vsync = (cnt_v  <=  V_SYNC - 1'd1) ? 1'b1 : 1'b0  ;
    
    //rgb_valid:VGA��Ч��ʾ���� 
    assign  rgb_valid = ((cnt_h >= H_SYNC + H_BACK + H_LEFT)
                        && (cnt_h < H_SYNC + H_BACK + H_LEFT + H_VALID)//���ź�����Ч����
                        &&((cnt_v >= V_SYNC + V_BACK + V_TOP)                     
                        && (cnt_v < V_SYNC + V_BACK + V_TOP + V_VALID))) //���ź�����Ч����
                        ? 1'b1 : 1'b0;
    
    //pix_data_req:���ص�ɫ����Ϣ�����ź�,��ǰrgb_valid�ź�һ��ʱ������ 
    assign  pix_data_req = (((cnt_h >= H_SYNC + H_BACK + H_LEFT - 1'b1)                     
                           && (cnt_h < H_SYNC + H_BACK + H_LEFT + H_VALID - 1'b1))
                           &&((cnt_v >= V_SYNC + V_BACK + V_TOP)
                           && (cnt_v < V_SYNC + V_BACK + V_TOP + V_VALID)))
                           ? 1'b1 : 1'b0;
                           
     //pix_x,pix_y:VGA��Ч��ʾ�������ص����� 
     assign  pix_x = (pix_data_req == 1'b1)? (cnt_h - (H_SYNC + H_BACK + H_LEFT - 1'b1)) : 10'h3ff; 
     assign  pix_y = (pix_data_req == 1'b1)? (cnt_v - (V_SYNC + V_BACK + V_TOP)) : 10'h3ff;
     
     //vsһ֡����ź�
     assign  vs  =  ((cnt_v == V_TOTAL - 1'd1) &&  (cnt_h == H_TOTAL-1'd1))?  1'b1 : 0;
     
     //rgb:������ص�ɫ����Ϣ 
     assign  rgb = (rgb_valid == 1'b1) ? pix_data : 12'b0 ;
  
endmodule
