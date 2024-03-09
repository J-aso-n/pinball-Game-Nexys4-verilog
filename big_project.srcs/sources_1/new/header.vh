//二维数组打包为一维数组
`define PACK_ARRAY(PK_WIDTH,PK_LEN,PK_SRC,PK_DEST) \
                generate \
                genvar pk_idx; \
                for (pk_idx=0; pk_idx<(PK_LEN); pk_idx=pk_idx+1) \
                begin \
                        assign PK_DEST[((PK_WIDTH)*pk_idx+((PK_WIDTH)-1)):((PK_WIDTH)*pk_idx)] = PK_SRC[pk_idx][((PK_WIDTH)-1):0]; \
                end \
                endgenerate

//一维数组展开为二维数组
`define UNPACK_ARRAY(PK_WIDTH,PK_LEN,PK_DEST,PK_SRC) \
                generate \
                genvar unpk_idx; \
                for (unpk_idx=0; unpk_idx<(PK_LEN); unpk_idx=unpk_idx+1) \
                begin \
                        assign PK_DEST[unpk_idx][((PK_WIDTH)-1):0] = PK_SRC[((PK_WIDTH)*unpk_idx+(PK_WIDTH-1)):((PK_WIDTH)*unpk_idx)]; \
                end \
                endgenerate

//根据坐标对应ram的值
`define get_ram(pix_x,pix_y,max,min) \
       if(pix_x >= 0 * WIDTH && pix_x <= 1 * WIDTH && pix_y >= 0 * HEIGHT && pix_y <= 1 * HEIGHT)\
       begin \
           max <= 7; min <=0; \
       end \
       else if(pix_x >= 1 * WIDTH && pix_x <= 2 * WIDTH && pix_y >= 0 * HEIGHT && pix_y <= 1 * HEIGHT)\
       begin \
           max <= 15; min <= 8; \
       end \
       else if(pix_x >= 2 * WIDTH && pix_x <= 3 * WIDTH && pix_y >= 0 * HEIGHT && pix_y <= 1 * HEIGHT)\
       begin \
           max <= 23; min <= 16; \
       end \
       else if(pix_x >= 3 * WIDTH && pix_x <= 4 * WIDTH && pix_y >= 0 * HEIGHT && pix_y <= 1 * HEIGHT)\
       begin \
           max <= 31; min <= 24; \
       end \
       else if(pix_x >= 0 * WIDTH && pix_x <= 1 * WIDTH && pix_y >= 1 * HEIGHT && pix_y <= 2 * HEIGHT)\
       begin \
           max <= 39; min <= 32; \
       end \
       else if(pix_x >= 1 * WIDTH && pix_x <= 2 * WIDTH && pix_y >= 1 * HEIGHT && pix_y <= 2 * HEIGHT)\
       begin \
           max <= 47; min <= 40; \
       end  \
       else if(pix_x >= 2 * WIDTH && pix_x <= 3 * WIDTH && pix_y >= 1 * HEIGHT && pix_y <= 2 * HEIGHT)\
       begin \
           max <= 55; min <= 48; \
       end \
       else if(pix_x >= 3 * WIDTH && pix_x <= 4 * WIDTH && pix_y >= 1 * HEIGHT && pix_y <= 2 * HEIGHT)\
       begin \
           max <= 63; min <= 56; \
       end \
       else if(pix_x >= 0 * WIDTH && pix_x <= 1 * WIDTH && pix_y >= 2 * HEIGHT && pix_y <= 3 * HEIGHT)\
       begin \
           max <= 71; min <= 64; \
       end \
       else if(pix_x >= 1 * WIDTH && pix_x <= 2 * WIDTH && pix_y >= 2 * HEIGHT && pix_y <= 3 * HEIGHT)\
       begin \
           max <= 79; min <= 72; \
       end  \
       else if(pix_x >= 2 * WIDTH && pix_x <= 3 * WIDTH && pix_y >= 2 * HEIGHT && pix_y <= 3 * HEIGHT)\
       begin \
           max <= 87; min <= 80; \
       end \
       else if(pix_x >= 3 * WIDTH && pix_x <= 4 * WIDTH && pix_y >= 2 * HEIGHT && pix_y <= 3 * HEIGHT)\
       begin \
           max <= 95; min <= 88; \
       end  \
       else if(pix_x >= 0 * WIDTH && pix_x <= 1 * WIDTH && pix_y >= 3 * HEIGHT && pix_y <= 4 * HEIGHT)\
       begin \
           max <= 103; min <= 96; \
       end \
       else if(pix_x >= 1 * WIDTH && pix_x <= 2 * WIDTH && pix_y >= 3 * HEIGHT && pix_y <= 4 * HEIGHT)\
       begin \
           max <= 111; min <= 104; \
       end  \
       else if(pix_x >= 2 * WIDTH && pix_x <= 3 * WIDTH && pix_y >= 3 * HEIGHT && pix_y <= 4 * HEIGHT)\
       begin \
           max <= 119; min <= 112; \
       end \
       else if(pix_x >= 3 * WIDTH && pix_x <= 4 * WIDTH && pix_y >= 3 * HEIGHT && pix_y <= 4 * HEIGHT)\
       begin \
           max <= 127; min <= 120; \
       end 
                
//vga方块颜色选取
`define PIX_IF \
    if(message ==8'h31) \
         pix_data  <=  RED; \
    else if(message ==8'h32) \
         pix_data  <=  ORANGE; \
    else if(message ==8'h33)   \
         pix_data  <=  YELLOW; \
    else if(message ==8'h34)   \
         pix_data  <=  GREEN;  \
    else if(message ==8'h35)   \
         pix_data  <=  CYAN;  \
    else if(message ==8'h36)   \
         pix_data  <=  BLUE;  \
    else if(message ==8'h37)   \
         pix_data  <=  PURPPLE;  \
    else if(message ==8'h38)   \
         pix_data  <=  BLACK;  \
    else if(message ==8'h39)   \
         pix_data  <=  GRAY;  \
    else                       \
         pix_data  <=  WHITE;

//小球x方向改变
`define X_DIREC_CHANGE \
    if(x_direction  ==  LEFT) \
    begin \
        x_direction = RIGHT; \
   end \
    else if(x_direction  ==  RIGHT) \
    begin \
        x_direction  =  LEFT; \
    end 

//小球y方向改变
`define Y_DIREC_CHANGE \
    if(y_direction  ==  UP) \
    begin \
        y_direction <= DOWN; \
    end \
    else if(y_direction  ==  DOWN) \
    begin \
        y_direction  <=  UP; \
    end 