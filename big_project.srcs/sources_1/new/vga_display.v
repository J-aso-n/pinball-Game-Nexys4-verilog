`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2023/01/31 22:51:19
// Design Name: 
// Module Name: vga_display
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

`include "header.vh"
module vga_display(
    input   vga_clk ,   //���빤��ʱ��,Ƶ��25MHz
    input   vs,         //һ֡�Ƿ����
    input   rst_n ,     //���븴λ�ź�,�͵�ƽ��Ч
    input   [9:0]   pix_x ,   //����VGA��Ч��ʾ�������ص�X������     
    input   [9:0]   pix_y ,   //����VGA��Ч��ʾ�������ص�Y������
    input   [127:0]   ram ,   //��������ĵ�ͼ��Ϣ
    input   game_start,      //�ߵ�ƽ��Ϸ��ʼ
    input  [9:0] BOARD_x,
    input  [9:0] BOARD_y,//��������
    output  reg  [11:0]  pix_data        //������ص�ɫ����Ϣ
    );
    parameter   H_VALID =   10'd640 ,   //����Ч����
                V_VALID =   10'd480 ;   //����Ч����
    //RGB444����ɫ����
    parameter   RED     =   12'hF00,   //��ɫ            
                ORANGE  =   12'hF09,   //��ɫ(��Ϊ��ɫ)
                YELLOW  =   12'hFF0,   //��ɫ
                GREEN   =   12'h0F0,   //��ɫ 
                CYAN    =   12'h0FF,   //��ɫ 
                BLUE    =   12'h00F,   //��ɫ 
                PURPPLE =   12'hF0F,   //��ɫ  
                BLACK   =   12'h000,   //��ɫ 
                WHITE   =   12'hFFF,   //��ɫ 
                GRAY    =   12'hA4A;   //��ɫ
    parameter   Radium   =   5,   //С��뾶
                Color   =   BLACK;  //С����ɫ
    reg  [9:0]  Ball_x  =  H_VALID / 2;
    reg  [9:0]  Ball_y  =  300;  //С������
    //���涨��С���˶�����
    parameter   UP   =   0,
                DOWN  =  1,
                LEFT  =  2,
                RIGHT =  3;//�˶�����
    reg  [1:0]  x_direction  =  RIGHT;
    reg  [1:0]  y_direction  =  UP;//С���˶�����
    reg  [9:0]  speed_x  =  1;
    reg  [9:0]  speed_y  =  1;//С���ٶ�
    //���涨�廬�����
    parameter   BOARD_W  =  100,//���ӿ��
                 BOARD_H  =  15, //���Ӹ߶�
                 BOARD_COLOR  =  RED;//������ɫ
    //���涨���ͼ����
    parameter  WIDTH  =  160,//������
               HEIGHT  =  50,//����߶�
               ROW     =  4;  //�����������
    reg  [7:0]  message;  //��ʱ��ͼ��ɫreg
    reg  [127:0]  vga_ram; //ram��reg��̬
    reg  [9:0]  max,min;  //ram����
    reg  change;//�ȱ��ٶȷ����ٱ���ɫ
    reg  game_end;//��Ϸ����
    
    integer rst_cnt;
    //vga_ram����
    always @(posedge vga_clk or  negedge rst_n)
    begin
        if(!rst_n)
        begin
            for(rst_cnt = 0;rst_cnt <= 127;rst_cnt = rst_cnt + 1)
                 vga_ram[rst_cnt] <= 0;//��λ
        end
        else if(!game_start) //�͵�ƽ�����ص�ͼ
        begin
            for(rst_cnt = 0;rst_cnt <= 127;rst_cnt = rst_cnt + 1)
                 vga_ram[rst_cnt] <= ram[rst_cnt];//��λ
        end
        else if(Ball_y >= 0 && Ball_y <= ROW * HEIGHT && Ball_x >= 0 * WIDTH && Ball_x <= H_VALID && change == 1)
        begin  //С���������飬������
           if(max == 7 && min == 0)
               vga_ram[7:0] <= 8'h0;
           else if(max == 15 && min == 8)
               vga_ram[15:8] <= 8'h0;
           else if(max == 23 && min == 16)
               vga_ram[23:16] <= 8'h0;
           else if(max == 31 && min == 24)
               vga_ram[31:24] <= 8'h0;
           else if(max == 39 && min == 32)
               vga_ram[39:32] <= 8'h0;
           else if(max == 47 && min == 40)
               vga_ram[47:40] <= 8'h0;
           else if(max == 55 && min == 48)
               vga_ram[55:48] <= 8'h0;
           else if(max == 63 && min == 56)
               vga_ram[63:56] <= 8'h0;  
           else if(max == 71 && min == 64)
               vga_ram[71:64] <= 8'h0;
           else if(max == 79 && min == 72)
               vga_ram[79:72] <= 8'h0;
           else if(max == 87 && min == 80)
               vga_ram[87:80] <= 8'h0;
           else if(max == 95 && min == 88)
               vga_ram[95:88] <= 8'h0;  
           else if(max == 103 && min == 96)
               vga_ram[103:96] <= 8'h0;
           else if(max == 111 && min == 104)
               vga_ram[111:104] <= 8'h0;
           else if(max == 119 && min == 112)
               vga_ram[119:112] <= 8'h0;
           else if(max == 127 && min == 120)
               vga_ram[127:120] <= 8'h0;                                                                                  
        end
    end
    
    //����С���ʱ���ڵ�����õ���ʱ����vga_ram����һ���ֽ���
    always @(posedge vga_clk or  negedge rst_n)
    begin
        if(rst_n == 0)      
        begin
            max   <=  0;//��λ
            min   <=  0;
        end
        else if(Ball_y >= 0 && Ball_y <= ROW * HEIGHT && Ball_x >= 0 *WIDTH && Ball_x <= H_VALID)//С���ڷ�������
        begin
            `get_ram(Ball_x,Ball_y,max,min)
        end
    end
    
    //pix_data��ɫ
    always @(posedge vga_clk or  negedge rst_n)
    begin
        if(rst_n == 0)      
        begin
            pix_data   <=  0;//��λ
        end
        else if((pix_x - Ball_x) * (pix_x - Ball_x) + (pix_y - Ball_y) * (pix_y - Ball_y) <= Radium * Radium)//x2+y2<=r2��ʾС��
        begin
            pix_data   <=  Color;
        end
        else if(pix_x >= BOARD_x && pix_x <= BOARD_x + BOARD_W && pix_y >= BOARD_y && pix_y <= BOARD_y + BOARD_H)//��������
        begin
            pix_data   <=  BOARD_COLOR;
        end
        else if(pix_y >=0 && pix_y< ROW * HEIGHT) //ש������
        begin
        if(pix_x >= 0 * WIDTH && pix_x < 1 * WIDTH && pix_y >= 0 * HEIGHT && pix_y < 1 * HEIGHT)
        begin
            message  <=  vga_ram[7:0];
            `PIX_IF
        end
        else if(pix_x >= 1 * WIDTH && pix_x < 2 * WIDTH && pix_y >= 0 * HEIGHT && pix_y < 1 * HEIGHT)
        begin
            message  <=  vga_ram[15:8];
            `PIX_IF
        end
        else if(pix_x >= 2 * WIDTH && pix_x < 3 * WIDTH && pix_y >= 0 * HEIGHT && pix_y < 1 * HEIGHT)
        begin
            message  <=  vga_ram[23:16];
            `PIX_IF
        end
        else if(pix_x >= 3 * WIDTH && pix_x < 4 * WIDTH && pix_y >= 0 * HEIGHT && pix_y < 1 * HEIGHT)
        begin
            message  <=  vga_ram[31:24];
            `PIX_IF
        end
        else if(pix_x >= 0 * WIDTH && pix_x < 1 * WIDTH && pix_y >= 1 * HEIGHT && pix_y < 2 * HEIGHT)
        begin
            message  <=  vga_ram[39:32];
            `PIX_IF
        end
        else if(pix_x >= 1 * WIDTH && pix_x < 2 * WIDTH && pix_y >= 1 * HEIGHT && pix_y < 2 * HEIGHT)
        begin
            message  <=  vga_ram[47:40];
            `PIX_IF
        end
        else if(pix_x >= 2 * WIDTH && pix_x < 3 * WIDTH && pix_y >= 1 * HEIGHT && pix_y < 2 * HEIGHT)
        begin
            message  <=  vga_ram[55:48];
            `PIX_IF
        end
        else if(pix_x >= 3 * WIDTH && pix_x < 4 * WIDTH && pix_y >= 1 * HEIGHT && pix_y < 2 * HEIGHT)
        begin
            message  <=  vga_ram[63:56];
            `PIX_IF
        end
        else if(pix_x >= 0 * WIDTH && pix_x < 1 * WIDTH && pix_y >= 2 * HEIGHT && pix_y < 3 * HEIGHT)
        begin
            message  <=  vga_ram[71:64];
            `PIX_IF
        end
        else if(pix_x >= 1 * WIDTH && pix_x < 2 * WIDTH && pix_y >= 2 * HEIGHT && pix_y < 3 * HEIGHT)
        begin
            message  <=  vga_ram[79:72];
            `PIX_IF
        end
        else if(pix_x >= 2 * WIDTH && pix_x < 3 * WIDTH && pix_y >= 2 * HEIGHT && pix_y < 3 * HEIGHT)
        begin
            message  <=  vga_ram[87:80];
            `PIX_IF
        end
        else if(pix_x >= 3 * WIDTH && pix_x < 4 * WIDTH && pix_y >= 2 * HEIGHT && pix_y < 3 * HEIGHT)
        begin
            message  <=  vga_ram[95:88];
            `PIX_IF
        end
        else if(pix_x >= 0 * WIDTH && pix_x < 1 * WIDTH && pix_y >= 3 * HEIGHT && pix_y < 4 * HEIGHT)
        begin
            message  <=  vga_ram[103:96];
            `PIX_IF
        end
        else if(pix_x >= 1 * WIDTH && pix_x < 2 * WIDTH && pix_y >= 3 * HEIGHT && pix_y < 4 * HEIGHT)
        begin
            message  <=  vga_ram[111:104];
            `PIX_IF
        end
        else if(pix_x >= 2 * WIDTH && pix_x < 3 * WIDTH && pix_y >= 3 * HEIGHT && pix_y < 4 * HEIGHT)
        begin
            message  <=  vga_ram[119:112];
            `PIX_IF
        end
        else if(pix_x >= 3 * WIDTH && pix_x < 4 * WIDTH && pix_y >= 3 * HEIGHT && pix_y < 4 * HEIGHT)
        begin
            message  <=  vga_ram[127:120];
            `PIX_IF
        end
        end
        else
            pix_data   <=  WHITE;
    end
    
    //С���˶�
    always @(posedge vs or negedge rst_n)
    begin
        //�˶�
        if( !rst_n)//��λ
        begin
            Ball_x <= H_VALID / 2;
            Ball_y <= 300;
            x_direction  <=  RIGHT;
            y_direction  <=  UP;
            game_end <= 0;
        end
        else begin
        if(game_start && !game_end)
        begin
        if(x_direction  ==  LEFT)
            Ball_x <= Ball_x - speed_x;
        else
            Ball_x <= Ball_x + speed_x;
        if(y_direction  ==  UP)
            Ball_y <= Ball_y - speed_y;
        else
            Ball_y <= Ball_y + speed_y;
        end
        //�������
        if(Ball_x == H_VALID)
             x_direction  <=  LEFT;
        if(Ball_x == 0)
             x_direction  <=  RIGHT;
        if(Ball_y == 0)
             y_direction  <=  DOWN;
         if(Ball_y == V_VALID)//��Ϸ����
         begin
             game_end <= 1;
             Ball_x <= H_VALID / 2;
             Ball_y <= 300;
         end
        if((Ball_y == 2 * HEIGHT  && Ball_x >= 3*WIDTH && Ball_x < 4*WIDTH && vga_ram[63:56] != 0)//��������
              ||(Ball_y == 2 * HEIGHT  && Ball_x >= 2*WIDTH && Ball_x < 3*WIDTH && vga_ram[55:48] != 0)//��������
              ||(Ball_y == 2 * HEIGHT  && Ball_x >= 0*WIDTH && Ball_x < 1*WIDTH && vga_ram[39:32] != 0)
              ||(Ball_y == 2 * HEIGHT  && Ball_x >= 1*WIDTH && Ball_x < 2*WIDTH && vga_ram[47:40] != 0)
              ||(Ball_y == 4 * HEIGHT  && Ball_x >= 3*WIDTH && Ball_x < 4*WIDTH && vga_ram[127:120] != 0)
              ||(Ball_y == 4 * HEIGHT  && Ball_x >= 2*WIDTH && Ball_x < 3*WIDTH && vga_ram[119:112] != 0)
              ||(Ball_y == 4 * HEIGHT  && Ball_x >= 1*WIDTH && Ball_x < 2*WIDTH && vga_ram[111:104] != 0)
              ||(Ball_y == 4 * HEIGHT  && Ball_x >= 0*WIDTH && Ball_x < 1*WIDTH && vga_ram[103:96] != 0)
              ||(Ball_y == 3 * HEIGHT  && Ball_x >= 3*WIDTH && Ball_x < 4*WIDTH && vga_ram[95:88] != 0)
              ||(Ball_y == 3 * HEIGHT  && Ball_x >= 2*WIDTH && Ball_x < 3*WIDTH && vga_ram[87:80] != 0)
              ||(Ball_y == 3 * HEIGHT  && Ball_x >= 1*WIDTH && Ball_x < 2*WIDTH && vga_ram[79:72] != 0)
              ||(Ball_y == 3 * HEIGHT  && Ball_x >= 0*WIDTH && Ball_x < 1*WIDTH && vga_ram[71:64] != 0)
              ||(Ball_y == 1 * HEIGHT  && Ball_x >= 3*WIDTH && Ball_x < 4*WIDTH && vga_ram[31:24] != 0)
              ||(Ball_y == 1 * HEIGHT  && Ball_x >= 2*WIDTH && Ball_x < 3*WIDTH && vga_ram[23:16] != 0)
              ||(Ball_y == 1 * HEIGHT  && Ball_x >= 0*WIDTH && Ball_x < 1*WIDTH && vga_ram[7:0] != 0)//��������
              ||(Ball_y == 1 * HEIGHT  && Ball_x >= 1*WIDTH && Ball_x < 2*WIDTH && vga_ram[15:8] != 0))//��������
        begin
           `Y_DIREC_CHANGE
           change <= 1;
        end
        else if((Ball_x == 1 * WIDTH 
                &&((Ball_y >= 1 * HEIGHT && Ball_y <= 2 * HEIGHT && (vga_ram[39:32] != 0 || vga_ram[47:40] != 0))
                ||(Ball_y >= 0 * HEIGHT && Ball_y <= 1 * HEIGHT && (vga_ram[7:0] != 0 || vga_ram[15:8] != 0))
                ||(Ball_y >= 2 * HEIGHT && Ball_y <= 3 * HEIGHT && (vga_ram[71:64] != 0 || vga_ram[79:72] != 0))
                ||(Ball_y >= 3 * HEIGHT && Ball_y <= 4 * HEIGHT && (vga_ram[103:96] != 0 || vga_ram[111:104] != 0))
                ))||
                (Ball_x == 2 * WIDTH 
                 &&((Ball_y >= 1 * HEIGHT && Ball_y <= 2 * HEIGHT && (vga_ram[47:40] != 0 || vga_ram[55:48] != 0))
                 ||(Ball_y >= 0 * HEIGHT && Ball_y <= 1 * HEIGHT && (vga_ram[15:8] != 0 || vga_ram[23:16] != 0))
                 ||(Ball_y >= 2 * HEIGHT && Ball_y <= 3 * HEIGHT && (vga_ram[79:72] != 0 || vga_ram[87:80] != 0))
                 ||(Ball_y >= 3 * HEIGHT && Ball_y <= 4 * HEIGHT && (vga_ram[111:104] != 0 || vga_ram[119:112] != 0))
                ))||
                (Ball_x == 3 * WIDTH 
                 &&((Ball_y >= 1 * HEIGHT && Ball_y <= 2 * HEIGHT && (vga_ram[55:48] != 0 || vga_ram[63:56] != 0))
                 ||(Ball_y >= 0 * HEIGHT && Ball_y <= 1 * HEIGHT && (vga_ram[23:16] != 0 || vga_ram[31:24] != 0))
                 ||(Ball_y >= 2 * HEIGHT && Ball_y <= 3 * HEIGHT && (vga_ram[87:80] != 0 || vga_ram[95:88] != 0))
                 ||(Ball_y >= 3 * HEIGHT && Ball_y <= 4 * HEIGHT && (vga_ram[119:112] != 0 || vga_ram[127:120] != 0))
                ))
                )
        begin
             `X_DIREC_CHANGE
             change  <= 1;
        end
        else
           change  <=  0;
        
        if(Ball_y == BOARD_y && Ball_x >= BOARD_x && Ball_x <= BOARD_x + BOARD_W)//������������
        begin
            `Y_DIREC_CHANGE
            Ball_y <= Ball_y - 1;
        end
        else  if((Ball_x == BOARD_x || Ball_x == BOARD_x + BOARD_W) && Ball_y >= BOARD_y && Ball_y <= BOARD_y + BOARD_H )//������������
        begin
            if(x_direction == RIGHT)
                Ball_x <= Ball_x - speed_x;
            else if(x_direction == LEFT)
                Ball_x <= Ball_x + speed_x;
            `Y_DIREC_CHANGE
            `X_DIREC_CHANGE
            Ball_y <= Ball_y - 1;
            
        end
        end
    end
    
    //�����˶�д��mouse��
 
endmodule
