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
    input   vga_clk ,   //输入工作时钟,频率25MHz
    input   vs,         //一帧是否完成
    input   rst_n ,     //输入复位信号,低电平有效
    input   [9:0]   pix_x ,   //输入VGA有效显示区域像素点X轴坐标     
    input   [9:0]   pix_y ,   //输入VGA有效显示区域像素点Y轴坐标
    input   [127:0]   ram ,   //蓝牙传入的地图信息
    input   game_start,      //高电平游戏开始
    input  [9:0] BOARD_x,
    input  [9:0] BOARD_y,//板子坐标
    output  reg  [11:0]  pix_data        //输出像素点色彩信息
    );
    parameter   H_VALID =   10'd640 ,   //行有效数据
                V_VALID =   10'd480 ;   //场有效数据
    //RGB444的颜色代码
    parameter   RED     =   12'hF00,   //红色            
                ORANGE  =   12'hF09,   //橙色(改为粉色)
                YELLOW  =   12'hFF0,   //黄色
                GREEN   =   12'h0F0,   //绿色 
                CYAN    =   12'h0FF,   //青色 
                BLUE    =   12'h00F,   //蓝色 
                PURPPLE =   12'hF0F,   //紫色  
                BLACK   =   12'h000,   //黑色 
                WHITE   =   12'hFFF,   //白色 
                GRAY    =   12'hA4A;   //灰色
    parameter   Radium   =   5,   //小球半径
                Color   =   BLACK;  //小球颜色
    reg  [9:0]  Ball_x  =  H_VALID / 2;
    reg  [9:0]  Ball_y  =  300;  //小球坐标
    //下面定义小球运动参数
    parameter   UP   =   0,
                DOWN  =  1,
                LEFT  =  2,
                RIGHT =  3;//运动方向
    reg  [1:0]  x_direction  =  RIGHT;
    reg  [1:0]  y_direction  =  UP;//小球运动方向
    reg  [9:0]  speed_x  =  1;
    reg  [9:0]  speed_y  =  1;//小球速度
    //下面定义滑板参数
    parameter   BOARD_W  =  100,//板子宽度
                 BOARD_H  =  15, //板子高度
                 BOARD_COLOR  =  RED;//板子颜色
    //下面定义地图参数
    parameter  WIDTH  =  160,//方块宽度
               HEIGHT  =  50,//方块高度
               ROW     =  4;  //方块最大行数
    reg  [7:0]  message;  //此时地图颜色reg
    reg  [127:0]  vga_ram; //ram的reg形态
    reg  [9:0]  max,min;  //ram参数
    reg  change;//先变速度方向再变颜色
    reg  game_end;//游戏结束
    
    integer rst_cnt;
    //vga_ram加载
    always @(posedge vga_clk or  negedge rst_n)
    begin
        if(!rst_n)
        begin
            for(rst_cnt = 0;rst_cnt <= 127;rst_cnt = rst_cnt + 1)
                 vga_ram[rst_cnt] <= 0;//复位
        end
        else if(!game_start) //低电平，加载地图
        begin
            for(rst_cnt = 0;rst_cnt <= 127;rst_cnt = rst_cnt + 1)
                 vga_ram[rst_cnt] <= ram[rst_cnt];//复位
        end
        else if(Ball_y >= 0 && Ball_y <= ROW * HEIGHT && Ball_x >= 0 * WIDTH && Ball_x <= H_VALID && change == 1)
        begin  //小球碰到方块，方块变白
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
    
    //根据小球此时所在的坐标得到此时处于vga_ram的哪一个字节中
    always @(posedge vga_clk or  negedge rst_n)
    begin
        if(rst_n == 0)      
        begin
            max   <=  0;//复位
            min   <=  0;
        end
        else if(Ball_y >= 0 && Ball_y <= ROW * HEIGHT && Ball_x >= 0 *WIDTH && Ball_x <= H_VALID)//小球在方块区域
        begin
            `get_ram(Ball_x,Ball_y,max,min)
        end
    end
    
    //pix_data上色
    always @(posedge vga_clk or  negedge rst_n)
    begin
        if(rst_n == 0)      
        begin
            pix_data   <=  0;//复位
        end
        else if((pix_x - Ball_x) * (pix_x - Ball_x) + (pix_y - Ball_y) * (pix_y - Ball_y) <= Radium * Radium)//x2+y2<=r2表示小球
        begin
            pix_data   <=  Color;
        end
        else if(pix_x >= BOARD_x && pix_x <= BOARD_x + BOARD_W && pix_y >= BOARD_y && pix_y <= BOARD_y + BOARD_H)//滑块区域
        begin
            pix_data   <=  BOARD_COLOR;
        end
        else if(pix_y >=0 && pix_y< ROW * HEIGHT) //砖块区域
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
    
    //小球运动
    always @(posedge vs or negedge rst_n)
    begin
        //运动
        if( !rst_n)//复位
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
        //方向控制
        if(Ball_x == H_VALID)
             x_direction  <=  LEFT;
        if(Ball_x == 0)
             x_direction  <=  RIGHT;
        if(Ball_y == 0)
             y_direction  <=  DOWN;
         if(Ball_y == V_VALID)//游戏结束
         begin
             game_end <= 1;
             Ball_x <= H_VALID / 2;
             Ball_y <= 300;
         end
        if((Ball_y == 2 * HEIGHT  && Ball_x >= 3*WIDTH && Ball_x < 4*WIDTH && vga_ram[63:56] != 0)//右下下沿
              ||(Ball_y == 2 * HEIGHT  && Ball_x >= 2*WIDTH && Ball_x < 3*WIDTH && vga_ram[55:48] != 0)//左下下沿
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
              ||(Ball_y == 1 * HEIGHT  && Ball_x >= 0*WIDTH && Ball_x < 1*WIDTH && vga_ram[7:0] != 0)//左上下沿
              ||(Ball_y == 1 * HEIGHT  && Ball_x >= 1*WIDTH && Ball_x < 2*WIDTH && vga_ram[15:8] != 0))//右上下沿
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
        
        if(Ball_y == BOARD_y && Ball_x >= BOARD_x && Ball_x <= BOARD_x + BOARD_W)//碰到板子上沿
        begin
            `Y_DIREC_CHANGE
            Ball_y <= Ball_y - 1;
        end
        else  if((Ball_x == BOARD_x || Ball_x == BOARD_x + BOARD_W) && Ball_y >= BOARD_y && Ball_y <= BOARD_y + BOARD_H )//碰到板子两边
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
    
    //滑板运动写在mouse中
 
endmodule
