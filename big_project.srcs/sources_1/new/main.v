`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2023/01/31 23:15:13
// Design Name: 
// Module Name: main
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
module main(
    input   sys_clk ,   //���빤��ʱ��     
    input   rst_n ,     //���븴λ�ź�,�͵�ƽ��Ч
    input   game_start ,//�ߵ�ƽ��Ϸ��ʼ
    input   rxd,        //��������
    inout	usb_clk,	//PS2ʱ������
    inout   usb_data,   //PS2��������
    output  txd,        //�������
    output  hsync ,     //�����ͬ���ź� 
    output  vsync ,     //�����ͬ���ź� 
    output  [11:0]  rgb //���������Ϣ��RGB444��
    );
    wire  [9:0]   pix_x;   //VGA��Ч��ʾ����X������
    wire  [9:0]   pix_y;   //VGA��Ч��ʾ����Y������
    wire  [11:0]  pix_data;//VGA���ص�ɫ����Ϣ
    wire  vs;              //����һ֡�Ƿ����
    wire [7:0] message;    //����������Ϣ,Ҫ��ʮ������HEX���
    reg  [7:0]  ram [15:0]; //�洢������Ϣ��4��8λ����,ע��������һ��λ��ͬ��Ҫ��
    wire  [127:0]  pack_ram;//�����һά�����ram
            `PACK_ARRAY(8,16,ram,pack_ram);
    wire  r_end;           //�ߵ�ƽ��ʾ�����������
    wire [9:0] BOARD_x;    //��������x
    wire [9:0] BOARD_y;    //��������y

    //��Ƶ�������õ�25MHzʱ��
    reg clk_25M;    //vga����ʱ��
    integer cnt=0;
    parameter N=4;
    always @(posedge sys_clk or negedge rst_n)
    begin
        if(rst_n == 0)//��ԭ
        begin
            clk_25M   <=  1'b0 ;
            cnt=0;
        end
        else
        begin
            if(cnt<N/2-1)
            begin
               cnt<=cnt+1;
               clk_25M<=clk_25M;
            end
            else
            begin
               cnt=0;
               clk_25M=~clk_25M;
            end
        end
    end
    
    //����ʱ�ӣ�����ȥ����������ģ����û��ʹ�õ���һ������ģ�飬���ÿɲ���
    wire  neg_clk;
    bluetooth_clk my_bluetooth_clk(
        sys_clk,
        rst_n,
        neg_clk
    );
    //�˴����账��ʱ������(�ѽ��)
    
    bluetooth  my_bluetooth(//��������ô������Ϣ�������һ�������Է��Ĺ���
        sys_clk, //����ʱ��
        rst_n,   //��λ
        rxd,     
        r_end,   //�������루һ�ֽڣ���ɱ�־
        message, //�������Ϣ
        txd
    );

    vga_ctrl  my_vga_ctrl(//ctrlģ�飬����vga�ܹ���ʾ
        clk_25M,
        rst_n,
        pix_data,  //�������ɫ��Ϣ
        pix_x,     //�������ɫ����
        pix_y,
        hsync,     //��ͬ���ź�
        vsync,
        rgb,       //�������ɫ��Ϣ
        vs         //һ֡���
    );
    vga_display  my_vga_display(//displayģ�飬vga������ʾ
        clk_25M,
        vs,         //һ֡��ɱ�־
        rst_n,
        pix_x,      //��ʱɨ������
        pix_y,
        pack_ram,   //������������Ϣ���������һά����
        game_start,
        BOARD_x,    //��������
        BOARD_y,
        pix_data    //�������ɫ
    );
    
    usb_mouse  my_mouse(
        sys_clk,
        rst_n,
        usb_clk,
        usb_data,
        BOARD_x,
        BOARD_y
    );
    
    //���洦��������Ϣ���浽ram�У���Ϊmodule���ܴ����ά���飬���������ﴦ��
    localparam IDLE = 2'b00,
               READ_vga = 2'b01,
               //READ_spin = 2'b10,
               READ_END = 2'b11;
    reg [1:0] cur_st,nxt_st;
    always@(posedge neg_clk or negedge rst_n)
    begin
        if(!rst_n)
            cur_st <=  IDLE;
        else
            cur_st <= nxt_st;
    end
    
    always@(*)begin
        case(cur_st)
            IDLE:begin
                if(r_end && message == 8'hff)   nxt_st=READ_vga;
            end
    
            READ_vga:if(message == 8'h0d)nxt_st=READ_END;
            
            //READ_spin:if(message == 8'h0d)nxt_st=READ_END;
    
            READ_END:nxt_st=IDLE;
    
            default:nxt_st=IDLE;  
        endcase    
    end

    reg [5:0] ram_in_cnt;//�洢���̼���
    integer rst_cnt;
    always @(posedge neg_clk or negedge rst_n)
    begin
        if(!rst_n ||(message == 8'hff))//ff��ʼ����
        begin
            for(rst_cnt = 0;rst_cnt <= 15;rst_cnt = rst_cnt + 1)
                 ram[rst_cnt] <= 8'h0;//��λ
            ram_in_cnt  <=  0;
        end
        else if (message == 8'h20 && ram[ram_in_cnt] != 0 && ram[ram_in_cnt+1] == 0 && cur_st == READ_vga)//������������Ų���һֱ����+1������ֻ��һһ��
            ram_in_cnt  <=  ram_in_cnt + 1;
        else if(message != 8'h20 && message != 8'h0d && message != 8'h0 && cur_st == READ_vga)
        begin
            ram[ram_in_cnt] <= message;//�洢��Ϣ
        end
        else if (message == 8'h0d )
            ram_in_cnt  <=  0;
        else
            ram_in_cnt  <=  ram_in_cnt;
    end
    
endmodule
