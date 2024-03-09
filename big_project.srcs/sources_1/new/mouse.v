`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2023/02/18 18:34:22
// Design Name: 
// Module Name: top
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


module usb_mouse #(
    parameter V_VALID = 480, //场有效高度
    parameter BOARD_W = 100, //板子宽度
    parameter speed = 3      //板子移动速度
)
(
    input             clk,         //系统时钟clk
    input             rst_n,         
    // PS2 port
    inout             USB_CLOCK,
    inout             USB_DATA,
    //板子坐标
    output    reg     [9:0]  BOARD_x = 50,
    output    reg     [9:0]  BOARD_y = V_VALID - 50
);

// USB ports control
wire   USB_CLOCK_OE;
wire   USB_DATA_OE;
wire   USB_CLOCK_out;
wire   USB_CLOCK_in;
wire   USB_DATA_out;
wire   USB_DATA_in;
assign USB_CLOCK = (USB_CLOCK_OE) ? USB_CLOCK_out : 1'bz;
assign USB_DATA = (USB_DATA_OE) ? USB_DATA_out : 1'bz;
assign USB_CLOCK_in = USB_CLOCK;
assign USB_DATA_in = USB_DATA;

wire       PS2_valid;
wire [7:0] PS2_data_in;
wire       PS2_busy;
wire       PS2_error;
wire       PS2_complete;
reg        PS2_enable;
reg  [7:0] PS2_data_out;

// Used for chipscope
reg  USB_CLOCK_d;
reg  USB_DATA_d;

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        USB_CLOCK_d <= 1'b0;
        USB_DATA_d  <= 1'b0;
    end
    else begin
        USB_CLOCK_d <= USB_CLOCK_in;
        USB_DATA_d <= USB_DATA_in;
    end
end

// Controller for the PS2 port
// Transfer parallel 8-bit data into serial, or receive serial to parallel
ps2_transmitter ps2_transmitter(
    .clk(clk),
    .rst(~rst_n),
    
    .clock_in(USB_CLOCK_in),
    .serial_data_in(USB_DATA_in),
    .parallel_data_in(PS2_data_in),
    .parallel_data_valid(PS2_valid),
    .busy(PS2_busy),
    .data_in_error(PS2_error),
    
    .clock_out(USB_CLOCK_out),
    .serial_data_out(USB_DATA_out),
    .parallel_data_out(PS2_data_out),
    .parallel_data_enable(PS2_enable),
    .data_out_complete(PS2_complete),
    
    .clock_output_oe(USB_CLOCK_OE),
    .data_output_oe(USB_DATA_OE)
);

genvar   i;
reg      move_left, move_right; //板子左右移

//16次循环，speed更快一点
generate
    for(i=0; i<16; i=i+1) begin : BOARD_control
        always @(posedge clk or negedge rst_n) begin
            if(!rst_n) begin
                BOARD_x <= 50;
                BOARD_y <= V_VALID - 50;
            end
            else if(move_left) begin
                if(BOARD_x > speed)
                     BOARD_x <= BOARD_x - speed;
                else
                     BOARD_x <= BOARD_x;
            end
            else if(move_right) begin
            if(BOARD_x < 640 - 100)
                 BOARD_x <= BOARD_x + speed;
            else
                 BOARD_x <= BOARD_x;
            end
        end
    end
endgenerate

// 状态机
localparam [3:0] IDLE = 4'd0;
localparam [3:0] SEND_RESET = 4'd1;
localparam [3:0] WAIT_ACKNOWLEDGE1 = 4'd2;
localparam [3:0] WAIT_SELF_TEST = 4'd3;
localparam [3:0] WAIT_MOUSE_ID = 4'd4;
localparam [3:0] ENABLE_DATA_REPORT = 4'd5;
localparam [3:0] WAIT_ACKNOWLEDGE2 = 4'd6;
localparam [3:0] GET_DATA1 = 4'd7;
localparam [3:0] GET_DATA2 = 4'd8;
localparam [3:0] GET_DATA3 = 4'd9;

reg [3:0] state;
reg [3:0] next_state;

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        state <= IDLE;
    end
    else begin
        state <= next_state;
    end
end

always @(posedge clk) begin
    case(state)
    IDLE: begin
        next_state <= SEND_RESET;
        PS2_enable <= 1'b0;
        PS2_data_out <= 8'h00;
    end
    // reset
    SEND_RESET: begin
        if(~PS2_busy && PS2_complete) begin
            next_state <= WAIT_ACKNOWLEDGE1;
            PS2_enable <= 1'b0;
        end
        else begin
            next_state <= SEND_RESET;
            PS2_enable <= 1'b1;
            PS2_data_out <= 8'hFF; //发送FF复位鼠标
        end
    end
    // Wait for the first acknowledge signal 0xFA
    WAIT_ACKNOWLEDGE1: begin
        if(PS2_valid && (PS2_data_in == 8'hFA)) begin   // 得到鼠标的回复
            next_state <= WAIT_SELF_TEST;
        end
        else begin
            next_state <= WAIT_ACKNOWLEDGE1;
        end
    end
    // The mouse will send back self-test pass signal 0xAA back first
    WAIT_SELF_TEST: begin
        if(PS2_valid && (PS2_data_in == 8'hAA)) begin   //自测试完成
            next_state <= WAIT_MOUSE_ID;
        end
        else begin
            next_state <= WAIT_SELF_TEST;
        end
    end
    // Then followed by the ID 0x00
    WAIT_MOUSE_ID: begin
        if(PS2_valid && (PS2_data_in == 8'h00)) begin   // 鼠标发送ID
            next_state <= ENABLE_DATA_REPORT;
        end
        else begin
            next_state <= WAIT_MOUSE_ID;
        end
    end
    // Enable data report mode 0xF4
    ENABLE_DATA_REPORT: begin
        if(~PS2_busy && PS2_complete) begin
            next_state <= WAIT_ACKNOWLEDGE2;
            PS2_enable <= 1'b0;
        end
        else begin
            next_state <= ENABLE_DATA_REPORT;
            PS2_enable <= 1'b1;
            PS2_data_out <= 8'hF4;   //发送鼠标使能F4
        end
    end
    // Wait for the second acknowledge signal 0xFA
    WAIT_ACKNOWLEDGE2: begin
        if(PS2_valid && (PS2_data_in == 8'hFA)) begin   // 得到鼠标回复
            next_state <= GET_DATA1;
        end
        else begin
            next_state <= WAIT_ACKNOWLEDGE2;
        end
    end
    // Get first byte from mouse, find if it's moving left or right, and if left clicked and right clicked
    // [4] is the XS bit, 1 means left, 0 means right
    // [1] is right click, [0] is left click, 1 means clicked
    // We don't get the distance here, for simplicity
    GET_DATA1: begin
        if(PS2_valid) begin
            move_left <= ((PS2_data_in[4]) | PS2_data_in[0]) ? 1'b1 : 1'b0;  //左移或左键
            move_right <= ((~PS2_data_in[4]) | PS2_data_in[1]) ? 1'b1 : 1'b0;//右移或右键
            next_state <= GET_DATA2;
        end
        else begin
            move_left <= 1'b0;
            move_right <= 1'b0;
            next_state <= GET_DATA1;
        end
    end
    // Second byte, X distance
    GET_DATA2: begin
        if(PS2_valid) begin
            next_state <= GET_DATA3;
        end
        else begin
            move_left <= 1'b0;
            move_right <= 1'b0;
            next_state <= GET_DATA2;
        end
    end
    // Third byte, Y distance, loop back to wait for next data packet
    GET_DATA3: begin
        if(PS2_valid) begin
            next_state <= GET_DATA1;
        end
        else begin
            next_state <= GET_DATA3;
        end
    end
    endcase
end

endmodule


