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
    input   sys_clk ,   //输入工作时钟     
    input   rst_n ,     //输入复位信号,低电平有效
    input   game_start ,//高电平游戏开始
    input   rxd,        //蓝牙读入
    inout	usb_clk,	//PS2时钟输入
    inout   usb_data,   //PS2数据输入
    output  txd,        //蓝牙输出
    output  hsync ,     //输出行同步信号 
    output  vsync ,     //输出场同步信号 
    output  [11:0]  rgb //输出像素信息（RGB444）
    );
    wire  [9:0]   pix_x;   //VGA有效显示区域X轴坐标
    wire  [9:0]   pix_y;   //VGA有效显示区域Y轴坐标
    wire  [11:0]  pix_data;//VGA像素点色彩信息
    wire  vs;              //定义一帧是否完成
    wire [7:0] message;    //蓝牙传输信息,要以十六进制HEX理解
    reg  [7:0]  ram [15:0]; //存储蓝牙信息，4个8位数组,注意下面有一个位置同步要改
    wire  [127:0]  pack_ram;//打包成一维数组的ram
            `PACK_ARRAY(8,16,ram,pack_ram);
    wire  r_end;           //高电平表示蓝牙传输结束
    wire [9:0] BOARD_x;    //滑板坐标x
    wire [9:0] BOARD_y;    //滑板坐标y

    //分频操作，得到25MHz时钟
    reg clk_25M;    //vga所用时钟
    integer cnt=0;
    parameter N=4;
    always @(posedge sys_clk or negedge rst_n)
    begin
        if(rst_n == 0)//复原
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
    
    //蓝牙时钟，可以去掉，在蓝牙模块中没有使用到，一个废弃模块，可用可不用
    wire  neg_clk;
    bluetooth_clk my_bluetooth_clk(
        sys_clk,
        rst_n,
        neg_clk
    );
    //此处还需处理时钟问题(已解决)
    
    bluetooth  my_bluetooth(//蓝牙，获得传入的信息，完成了一个自收自发的过程
        sys_clk, //蓝牙时钟
        rst_n,   //复位
        rxd,     
        r_end,   //蓝牙输入（一字节）完成标志
        message, //传入的信息
        txd
    );

    vga_ctrl  my_vga_ctrl(//ctrl模块，控制vga能够显示
        clk_25M,
        rst_n,
        pix_data,  //输入的颜色信息
        pix_x,     //输出的上色坐标
        pix_y,
        hsync,     //行同步信号
        vsync,
        rgb,       //输出的颜色信息
        vs         //一帧完成
    );
    vga_display  my_vga_display(//display模块，vga具体显示
        clk_25M,
        vs,         //一帧完成标志
        rst_n,
        pix_x,      //此时扫描坐标
        pix_y,
        pack_ram,   //蓝牙传来的信息，打包成了一维数组
        game_start,
        BOARD_x,    //板子坐标
        BOARD_y,
        pix_data    //输出的上色
    );
    
    usb_mouse  my_mouse(
        sys_clk,
        rst_n,
        usb_clk,
        usb_data,
        BOARD_x,
        BOARD_y
    );
    
    //下面处理蓝牙信息储存到ram中，因为module不能传入二维数组，所以在这里处理
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

    reg [5:0] ram_in_cnt;//存储过程计数
    integer rst_cnt;
    always @(posedge neg_clk or negedge rst_n)
    begin
        if(!rst_n ||(message == 8'hff))//ff开始接收
        begin
            for(rst_cnt = 0;rst_cnt <= 15;rst_cnt = rst_cnt + 1)
                 ram[rst_cnt] <= 8'h0;//复位
            ram_in_cnt  <=  0;
        end
        else if (message == 8'h20 && ram[ram_in_cnt] != 0 && ram[ram_in_cnt+1] == 0 && cur_st == READ_vga)//加上这个条件才不会一直进行+1，而是只加一一次
            ram_in_cnt  <=  ram_in_cnt + 1;
        else if(message != 8'h20 && message != 8'h0d && message != 8'h0 && cur_st == READ_vga)
        begin
            ram[ram_in_cnt] <= message;//存储信息
        end
        else if (message == 8'h0d )
            ram_in_cnt  <=  0;
        else
            ram_in_cnt  <=  ram_in_cnt;
    end
    
endmodule
