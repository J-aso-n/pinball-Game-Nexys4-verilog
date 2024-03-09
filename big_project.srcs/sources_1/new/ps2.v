`timescale 1ns / 1ps
//ps2协议实现
module ps2_transmitter(
    input            clk,               //100MHz
    input            rst,               //高电平复位
    // 输入模块数据
    input            clock_in,           // input的usb时钟
    input            serial_data_in,     // input的usb数据
    output reg [7:0] parallel_data_in,   // ubs输入的数据
    output reg       parallel_data_valid,// 高电平输入成功
    output reg       data_in_error,      // 奇偶校验失败标志
    
    // 输出模块数据
    output reg       clock_out,           // output的usb时钟
    output reg       serial_data_out,     // output的usb数据
    input      [7:0] parallel_data_out,   // 要输出的数据
    input            parallel_data_enable,// 输出使能
    output reg       data_out_complete,
    
    output reg       busy,                
    output reg       clock_output_oe,     // 输出时钟使能
    output reg       data_output_oe       // 输出数据使能
);

//状态机
parameter [3:0] IDLE = 4'd0;
parameter [3:0] WAIT_IO = 4'd1;
parameter [3:0] DATA_IN = 4'd2;
parameter [3:0] DATA_OUT = 4'd3;
parameter [3:0] INITIALIZE = 4'd4;

reg  [3:0]  state;
reg  [3:0]  next_state;

// Parallel data buffer
reg  [10:0] data_out_buf;
reg  [10:0] data_in_buf;
reg  [3:0]  data_count;

//时钟计数器
reg  [15:0] clock_count;

// 时钟下降沿探测
// If data coming in, then we cannot start writing data out
reg  [1:0]  clock_in_delay;
wire        clock_in_negedge;
always @(posedge clk) begin
    clock_in_delay <= {clock_in_delay[0], clock_in};
end
assign clock_in_negedge = (clock_in_delay == 2'b10) ? 1'b1 : 1'b0;

//状态机时序
always @(posedge clk or posedge rst) begin
    if(rst) begin
        state <= IDLE;
    end
    else begin
        state <= next_state;
    end
end

always @(posedge clk) begin
    case(state)
    IDLE: begin
        next_state <= WAIT_IO;
        clock_output_oe <= 1'b0;
        data_output_oe <= 1'b0;
        data_in_error <= 1'b0;
        data_count <= 4'd0;
        busy <= 1'b0;
        parallel_data_valid <= 1'b0;
        clock_count <= 16'd0;
        data_in_buf <= 11'h0;
        data_out_buf <= 11'h0;
        clock_out <= 1'b1;
        serial_data_out <= 1'b1;
        data_out_complete <= 1'b0;
        parallel_data_in <= 8'h00;
    end

    // 等待状态，当探测到时钟下降沿时，开启读取状态；当有送数据请求时，
    // 缓存好并行数据以及其奇偶校验位、结束位，开启送数据初始化状态。需要注意的是，
    // 在这一步中，读取或者送出初始低电平都直接完成了
    WAIT_IO: begin
        if(clock_in_negedge) begin  // input data detected, and the start bit is ignored
            next_state <= DATA_IN;
            busy <= 1'b1;
            data_count <= 4'd0;
        end
        else if(parallel_data_enable) begin // output data enable detected, and send out the start bit right here
            next_state <= INITIALIZE;
            busy <= 1'b1;
            data_count <= 4'd0;
            clock_output_oe <= 1'b1;
            clock_out <= 1'b0;  // drive low for about 60us to initialize output
            data_out_buf <= {parallel_data_out[0],parallel_data_out[1],parallel_data_out[2],parallel_data_out[3],
                             parallel_data_out[4],parallel_data_out[5],parallel_data_out[6],parallel_data_out[7],
                             ~^(parallel_data_out), 2'b11};
            data_output_oe <= 1'b1;
            serial_data_out <= 1'b0;
        end
    end

    // 读取数据状态，每个时钟下降沿就向移位寄存器中塞一位，
    //塞到10位，就可以逆序输出并行数据了，顺便检查一下奇偶校验位
    DATA_IN: begin
        if(clock_in_negedge && (data_count < 4'd10)) begin
            data_in_buf <= {data_in_buf[9:0], serial_data_in};
            data_count <= data_count + 4'd1;
        end
        else if(data_count == 4'd10) begin
            next_state <= IDLE;
            data_count <= 4'd0;
            busy <= 1'b0;
            parallel_data_valid <= 1'b1;
            parallel_data_in <= {data_in_buf[2],data_in_buf[3],data_in_buf[4],data_in_buf[5],
                                 data_in_buf[6],data_in_buf[7],data_in_buf[8],data_in_buf[9]};
            if(data_in_buf[1] == ^(data_in_buf[9:2])) begin
                data_in_error <= 1'b1;
            end
        end
    end

    //在发送数据状态前，把时钟和数据输出信号拉低60个微秒，然后放开时钟的输出控制，控制权交还给鼠标
    INITIALIZE : begin
        if(clock_count < 16'd6000) begin
            clock_count <= clock_count + 16'd1;
            clock_output_oe <= 1'b1;
            clock_out <= 1'b0;
        end
        else begin
            next_state <= DATA_OUT;
            clock_output_oe <= 1'b0;
            clock_out <= 1'b1;
        end
    end

    // 鼠标开始接收指令，并驱动时钟发送剩下的10位数
    DATA_OUT : begin
        if(clock_in_negedge) begin
            if(data_count < 4'd10) begin
                data_count <= data_count + 4'd1;
                serial_data_out <= data_out_buf[10];
                data_out_buf <= {data_out_buf[9:0], 1'b0};
            end
            else if(data_count == 4'd10) begin
                data_out_complete <= 1'b1;
                next_state <= IDLE;
                busy <= 1'b0;
            end
        end
    end
    endcase
end

endmodule

