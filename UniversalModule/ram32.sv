
module ram32 #(
    
    parameter ADDR_WIDTH = 32,                  //CPU地址总线宽度
    parameter DEPTH      = 1024                 //实际内存深度
) (

    input logic                     clk,
    input logic                     we,         //写入使能
    input logic [ADDR_WIDTH-1:0]    waddr,      //ADDR_WIDTH位地址
    input logic [ADDR_WIDTH-1:0]    raddr,      //ADDR_WIDTH位地址

    //写入类型，001：写入1个内存单元，010：写入2个内存单元，100：写入4个内存单元。都是连续的
    input logic [2:0]               types,      

    input logic [7:0]   cin0,                   //输入数据
    input logic [7:0]   cin1,                   
    input logic [7:0]   cin2,                   
    input logic [7:0]   cin3,                   
        
    output logic [7:0]  dout0,                  //输出数据
    output logic [7:0]  dout1,
    output logic [7:0]  dout2,
    output logic [7:0]  dout3
    
);


    //计算需要的索引位宽（< 32）
    localparam INDEX_WIDTH = $clog2(DEPTH);   //用 $clog2 自动求出最小位数

    //定义内存单元
    logic [7:0] mem_array [DEPTH - 1:0];

    //写地址链
    logic [INDEX_WIDTH-1:0] waddr0B, waddr1B, waddr2B, waddr3B;

    assign waddr0B = waddr[INDEX_WIDTH-1:0];
    assign waddr1B = waddr0B + 1;
    assign waddr2B = waddr0B + 2;
    assign waddr3B = waddr0B + 3;



    //同步写：只用低 INDEX_WIDTH 位
    always_ff @(posedge clk) begin
        if (we) begin
            case(types)
                3'b001: begin  //1B写
                    if (waddr0B < DEPTH) mem_array[waddr0B] <= cin0;
                end
                3'b010: begin  //2B写
                    if (waddr0B < DEPTH) mem_array[waddr0B] <= cin0;
                    if (waddr1B < DEPTH) mem_array[waddr1B] <= cin1;
                end
                3'b100: begin  //4B写
                    if (waddr0B < DEPTH) mem_array[waddr0B] <= cin0;
                    if (waddr1B < DEPTH) mem_array[waddr1B] <= cin1;
                    if (waddr2B < DEPTH) mem_array[waddr2B] <= cin2;
                    if (waddr3B < DEPTH) mem_array[waddr3B] <= cin3;
                end
                default: ;  //无操作
            endcase
        end
    end


    //读地址链
    logic [INDEX_WIDTH-1:0] raddr0B, raddr1B, raddr2B, raddr3B;

    assign raddr0B = raddr[INDEX_WIDTH-1:0];
    assign raddr1B = raddr0B + 1;
    assign raddr2B = raddr0B + 2;
    assign raddr3B = raddr0B + 3;

    //物理内存只分配 DEPTH 大小
    //逻辑读
    assign dout0 = (raddr0B < DEPTH) ? mem_array[raddr0B] : 8'b0;
    assign dout1 = (raddr1B < DEPTH) ? mem_array[raddr1B] : 8'b0;
    assign dout2 = (raddr2B < DEPTH) ? mem_array[raddr2B] : 8'b0;
    assign dout3 = (raddr3B < DEPTH) ? mem_array[raddr3B] : 8'b0; 

endmodule


