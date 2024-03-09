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
    input   vga_clk ,         //输入工作时钟,频率25MHz 
    input   rst_n ,           //复位信号,低电平有效     
    input   [11:0]  pix_data ,//输入像素点色彩信息
    output  [9:0]   pix_x ,   //输出VGA有效显示区域像素点X轴坐标 
    output  [9:0]   pix_y ,   //输出VGA有效显示区域像素点Y轴坐标 
    output  hsync ,           //行同步信号 (高电平有效)
    output  vsync ,           //场同步信号(列) 
    output  [11:0]  rgb ,     //输出像素点色彩信息
    output  vs                //一帧是否完成
    );
    
    /*
    parameter H_SYNC    =   10'd1  ,   //行同步时钟周期数           
                  H_BACK    =   10'd0  ,   //行时序后沿           
                  H_LEFT    =   10'd0   ,   //行时序左边框           
                  H_VALID   =   10'd4 ,   //行有效数据           
                  H_RIGHT   =   10'd5   ,   //行时序右边框           
                  H_FRONT   =   10'd6   ,   //行时序前沿           
                  H_TOTAL   =   10'd16 ;   //行扫描周期 
                  //800=96+40+8+640（有效）+8+8
        parameter V_SYNC    =   10'd1   ,   //场同步           
                  V_BACK    =   10'd0  ,   //场时序后沿     
                  V_TOP     =   10'd0   ,   //场时序上边框       
                  V_VALID   =   10'd4 ,   //场有效数据
                  V_BOTTOM  =   10'd5   ,   //场时序下边框    
                  V_FRONT   =   10'd6   ,   //场时序前沿       
                  V_TOTAL   =   10'd16 ;   //场扫描周期
                  */
    //采用1024*768@60显示模式(1024*768，帧数60)抛弃
    //采用640*480@60显示模式(640*480，帧数60)25MHz
    parameter H_SYNC    =   15'd96  ,   //行同步时钟周期数           
              H_BACK    =   15'd40  ,   //行时序后沿           
              H_LEFT    =   15'd8   ,   //行时序左边框           
              H_VALID   =   15'd640 ,   //行有效数据           
              H_RIGHT   =   15'd8   ,   //行时序右边框           
              H_FRONT   =   15'd8   ,   //行时序前沿           
              H_TOTAL   =   15'd800 ;   //行扫描周期 
    parameter V_SYNC    =   10'd2   ,   //场同步           
              V_BACK    =   10'd25  ,   //场时序后沿     
              V_TOP     =   10'd8   ,   //场时序上边框       
              V_VALID   =   10'd480 ,   //场有效数据
              V_BOTTOM  =   10'd8   ,   //场时序下边框    
              V_FRONT   =   10'd2   ,   //场时序前沿       
              V_TOTAL   =   10'd525 ;   //场扫描周期
              
    wire   rgb_valid       ;   //VGA有效显示区域 
    wire   pix_data_req    ;   //像素点色彩信息请求信号
    reg    [9:0]   cnt_h   ;   //行同步信号计数器 
    reg    [9:0]   cnt_v   ;   //场同步信号计数器
    
    //cnt_h:行同步信号计数器 
    always@(posedge vga_clk or  negedge rst_n)     
    if(rst_n == 0)         
       cnt_h   <=  0;//复位计数器清零     
    else   if(cnt_h == H_TOTAL - 1'd1)         
       cnt_h   <=  0;//到达行末，换行清零     
    else  
       cnt_h   <=  cnt_h + 1'd1;//正常加1
       
    //hsync:行同步信号 
    assign  hsync = (cnt_h  <=  H_SYNC - 1'd1) ? 1'b1 : 1'b0;
    
    //cnt_v:场同步信号计数器 
    always@(posedge vga_clk or  negedge rst_n)     
    if(rst_n == 0)      
    begin
        cnt_v   <=  0;//复位计数器清零
    end
    else if((cnt_v == V_TOTAL - 1'd1) &&  (cnt_h == H_TOTAL-1'd1))        
    begin
        cnt_v   <=  0;//到本次显示的最后一个位置，复位    
    end
    else if(cnt_h == H_TOTAL - 1'd1)        
    begin
        cnt_v   <=  cnt_v + 1'd1;//行信号到本行最后一个位置，场信号加一   
    end 
    else       
    begin
        cnt_v   <=  cnt_v;//正常情况不变
    end

    //vsync:场同步信号 
    assign  vsync = (cnt_v  <=  V_SYNC - 1'd1) ? 1'b1 : 1'b0  ;
    
    //rgb_valid:VGA有效显示区域 
    assign  rgb_valid = ((cnt_h >= H_SYNC + H_BACK + H_LEFT)
                        && (cnt_h < H_SYNC + H_BACK + H_LEFT + H_VALID)//行信号在有效区间
                        &&((cnt_v >= V_SYNC + V_BACK + V_TOP)                     
                        && (cnt_v < V_SYNC + V_BACK + V_TOP + V_VALID))) //场信号在有效区间
                        ? 1'b1 : 1'b0;
    
    //pix_data_req:像素点色彩信息请求信号,超前rgb_valid信号一个时钟周期 
    assign  pix_data_req = (((cnt_h >= H_SYNC + H_BACK + H_LEFT - 1'b1)                     
                           && (cnt_h < H_SYNC + H_BACK + H_LEFT + H_VALID - 1'b1))
                           &&((cnt_v >= V_SYNC + V_BACK + V_TOP)
                           && (cnt_v < V_SYNC + V_BACK + V_TOP + V_VALID)))
                           ? 1'b1 : 1'b0;
                           
     //pix_x,pix_y:VGA有效显示区域像素点坐标 
     assign  pix_x = (pix_data_req == 1'b1)? (cnt_h - (H_SYNC + H_BACK + H_LEFT - 1'b1)) : 10'h3ff; 
     assign  pix_y = (pix_data_req == 1'b1)? (cnt_v - (V_SYNC + V_BACK + V_TOP)) : 10'h3ff;
     
     //vs一帧完成信号
     assign  vs  =  ((cnt_v == V_TOTAL - 1'd1) &&  (cnt_h == H_TOTAL-1'd1))?  1'b1 : 0;
     
     //rgb:输出像素点色彩信息 
     assign  rgb = (rgb_valid == 1'b1) ? pix_data : 12'b0 ;
  
endmodule
