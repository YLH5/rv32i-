/*
 *                  ==<指令存储器 ROM 模块>==
 * 模块功能：
 *     存放指令程序，只读存储器。ROM 数据直接在模块中初始化，
 *     兼容模拟和综合，无需外部文件引用。 
 * 特性：
 *     - 参数化存储深度 (dep)，灵活配置存储容量
 *     - 异步读：组合逻辑直接输出指令
 *     - 地址截断，仅取低 INDEX 位
 *     - 在模块内使用 initial 块初始化 ROM 内容
 *
 * 使用方法：
 *     1. 在下方 initial 块中填入指令镜像数据（逐字节赋值或循环语句）。
 *     2. 编译和仿真时，initial 块会设置 mem 数组内容；综合工具会将其当作常量 ROM.
 */
module rom #(
    parameter bit_width = 32,        // 指令宽度（位）
    parameter dep       = 1024       // 存储深度（Byte 数）
)(
    input  logic [bit_width-1:0]     adr,  // 读地址（字节寻址）
    output logic [bit_width-1:0]     dout  // 输出 32 位指令
);

    // 计算地址索引宽度
    localparam INDEX = $clog2(dep);

    // 存储单位：Byte 地址空间
    logic [7:0] mem [0:dep-1];

    // ------------------------------------------------------------
    // ROM 内容初始化：在此填入指令镜像数据
    // 示例：两条指令 0x00000013, 0x01000093
    // ------------------------------------------------------------
    initial begin

        {mem[3], mem[2], mem[1], mem[0]}    = 32'h00000013;
        {mem[7], mem[6], mem[5], mem[4]}    = 32'h00000013;
        {mem[11], mem[10], mem[9], mem[8]}  = 32'h00000013;
        
    end

    // 截断地址为有效索引
    logic [INDEX-1:0] adrb = adr[INDEX-1:0];
    logic [7:0] adrb0 = adrb;
    logic [7:0] adrb1 = adrb0 + 1;
    logic [7:0] adrb2 = adrb1 + 1;
    logic [7:0] adrb3 = adrb2 + 1;

    // 异步读：组合逻辑输出 4 个连续字节组成的 32 位指令（小端格式）
    assign dout = {mem[adrb3], mem[adrb2], mem[adrb1], mem[adrb0] };

endmodule
