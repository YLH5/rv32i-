/*
 * 算术逻辑单元（ALU）模块
 * 
 * 操作类型控制码（ctrl[2:0]）:
 * [000] 加法运算        : out = a + b
 * [001] 减法运算        : out = a - b
 * [010] 有符号小于比较(slt)    : out = (a < b) ? 1 : 0 
 * [011] 无符号小于比较(sltu)   : out = (a < b) ? 1 : 0
 * [100] 按位异或        : out = a ^ b
 * [110] 按位或          : out = a | b
 * [111] 按位与          : out = a & b
 *
 * 状态标志输出（flags）:
 * [0] Z 零标志          : 结果为0时置位
 * [1] N 负标志          : 结果为负数时置位
 * [2] C 进位/借位标志    : 算术运算进位/借位时置位
 * [3] V 溢出标志         : 算术运算溢出时置位
 * [bit_width-1:4] 保留位
 */
module ALU #(
    parameter bit_width = 32  // 数据位宽（32/64位）
)(
    input  logic [2:0]           ctrl,  // 操作控制码
    input  logic [bit_width-1:0] a,     // 操作数A
    input  logic [bit_width-1:0] b,     // 操作数B
    output logic [bit_width-1:0] out,   // 运算结果
    output logic [bit_width-1:0] flags // 状态标志寄存器
);

    // ===================== 数据通路信号 =====================
    // ---- 算术运算调整信号 ----
    logic [bit_width-1:0] b_adj;    // B操作数调整 （取反用于减法）
    logic         cin_adj;          // 进位输入调整（减法时+1）
    
    // ---- 加法器信号 ----     
    logic [bit_width-1:0] cp_out;   // 加法器原始输出
    logic         cout;             // 加法器进位输出

    // ===================== 运算逻辑实现 =====================
    // 减法运算预处理：取反加1（补码转换）
    assign b_adj = (ctrl[1:0]) ? ~b : b;            // ctrl[1:0]非零时取反（减法/比较操作）
    assign cin_adj = (ctrl[1:0]) ? 1'b1 : 1'b0;     // 减法操作时附加进位1

    // 核心算术单元（支持加减法）
    adder32 #(.N(bit_width)) compute (
        .a(a),        // 原操作数A
        .b(b_adj),    // 调整后操作数B
        .cin(cin_adj),// 进位调整
        .sum(cp_out), // 原始计算结果
        .cout(cout)   // 进位输出
    );

    // ===================== 状态标志生成 =====================
    // 零标志（所有位都为0时置位）
    assign flags[0] = ~|out;  
    
    // 负标志（取最高符号位）
    assign flags[1] = out[bit_width-1];  
    
    // 进位/借位标志（算术运算有效时）
    assign flags[2] = ~ctrl[2] & (     // 仅算术操作有效
        (ctrl == 2'b01) ? ~cout : cout  // 减法借位取反
    );
    
    // 溢出标志（符号位异常时置位）
    assign flags[3] = ~ctrl[2] &                                         // 仅算术操作有效
        ( (a[bit_width-1] & b_adj[bit_width-1] & ~cp_out[bit_width-1]) |  // 负+负得正
          (~(a[bit_width-1] | b_adj[bit_width-1]) & cp_out[bit_width-1])  // 正+正得负
    );
    
    // 保留位清零
    assign flags[bit_width-1:4] = {(bit_width-4){1'b0}};

    // ===================== 结果选择逻辑 =====================
    always_comb begin
        case(ctrl)
            // 逻辑运算
            3'b100: out = a ^ b;    // 按位异或
            3'b110: out = a | b;    // 按位或
            3'b111: out = a & b;    // 按位与
            
            // 有符号比较slt（a < b）
            3'b010: out = {{(bit_width-1){1'b0}},  // 高位填充0
                // 符号位异常检测（溢出时反转结果）
                ((a[bit_width-1] ^ cp_out[bit_width-1]) & flags[3]) ^ 
                cp_out[bit_width-1]};  
            
            // 无符号比较sltu（a < b）
            3'b011: out = {{(bit_width-1){1'b0}}, ~cout};  // 借位标志取反
            
            // 默认算术运算结果
            default: out = cp_out;  // 直接使用加法器输出
        endcase
    end
    
endmodule
