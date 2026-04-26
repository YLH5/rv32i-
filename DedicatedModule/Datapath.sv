/*
 *
 *                  ==<RISC-V 32位数据通路>==
 * 模块功能：
 *          RISC-V的数据通路，涵盖了指令的获取、译码、执行、内存访问以及写回等阶段。
 *          它集成了多个子模块，包括程序计数器（ProgramCounter）、指令存储器（ROM）、寄存器堆（regfile）、
 *          立即数扩展器（extend）、算术逻辑单元（ALU）以及数据存储器（RAM）。
 *          控制信号由外部控制单元生成，指导数据在各个子模块之间的流动和处理。
 *
 *
 *
 * 部分输入端口说明：
 *
 *            
 *  RegWrite  —— 寄存器堆写使能
 *               1：在 clk 上升沿，将 wdata 写入寄存器
 *               0：禁止写寄存器
 *
 *  ALUSrc    —— ALU B 端口来源选择
 *               1：使用符号扩展后的立即数 immExt
 *               0：使用寄存器读出的rd2
 *
 *  ResultSrc —— 寄存器输入选择
 *               0：ALU输出写回寄存器（默认）
 *               1：从内存读出数据写入寄存器
 *
 *  ImmSrc[1:0]
 *           —— Extend 模块立即数来源控制
 *               00：I-Type（从指令[31:20]扩展）
 *               01：S-Type（拼接指令[31:25]和[11:7]）
 *               10：B-Type（拼接指令[31], [7], [30:20], [11:8], 1'b0）
 *
 *  PcSrc[1:0]—— 程序计数器更新方式
 *               00：PC <- 0（复位）
 *               01：PC <- PC + 4（顺序执行）
 *               10：PC <- pc_in（跳转/分支）
 *               11：PC <- PC（单指令循环）
 *
 *  ALUControl[2:0]
 *           —— ALU 运算类型
 *              000：加法     out = a + b
 *              001：减法     out = a - b
 *              010：有符号小于比较  out[0] = (a < b)?1:0，其他位 = 0
 *              011：无符号小于比较  out[0] = (a < b)?1:0，其他位 = 0
 *              100：按位异或 out = a ^ b
 *              110：按位或   out = a | b
 *              111：按位与   out = a & b
 *
 *
 *
 *
 * 部分输出端口说明：
 *
 *  pc_in     —— 跳转/分支目标地址输入(舍弃)
 *
 *  ALU_flags[bit_width-1:0]
 *           —— ALU状态标志输出
 *               [0]：Z 零标志 结果为0时置位
 *               [1]：N 负标志 结果为负数时置位
 *               [2]：C 进位/借位标志 算术运算进位/借位时置位
 *               [3]：V 溢出标志 算术运算溢出时置位
 *               [bit_width-1:4]： 保留位
 *
 *  out0–out2 —— 模块对外输出（可按需扩展）
 */

module Datapath #(
    parameter bit_width = 32
) (

    //==================== 指令存储器接口 ====================//
    input  logic [bit_width-1:0]    InstrIn,     // 指令输入（来自指令存储器）
    output logic [bit_width-1:0]    InstrMemAdr, // 指令地址输出（当前PC值）

    //==================== 数据存储器接口 ====================//
    input  logic [bit_width-1:0]    DataIn,      // 数据输入（来自数据存储器）
    output logic [2:0]              DataMemTypes,// 数据存取类型（1/2/4字节控制）
    output logic [bit_width-1:0]    DataMemAdr,  // 数据存储器地址（ALU计算结果）
    output logic [bit_width-1:0]    DataOut,     // 数据输出（写入存储器的数据）


    //==================== 控制信号输入 ====================//
    input  logic                    clk,         // 时钟，上升沿写寄存器/写内存
    input  logic                    RegWrite,    // 寄存器写使能
    input  logic                    ALUSrc,      // ALU B 端口选择
    input  logic                    ResultSrc,   // 寄存器写入选择
    input  logic [1:0]              ImmSrc,      // 立即数来源
    input  logic [1:0]              PcSrc,       // PC 更新方式
    input  logic [2:0]              ALUControl,  // ALU 运算类型

    output logic [bit_width-1:0]    ALU_flags,  // 输出ALU状态标志寄存器
    output logic [bit_width-1:0]    out0
);

    // ----------------------------------------------------------------
    // 内部信号声明
    // ----------------------------------------------------------------
    logic [bit_width-1:0] pc, pc_add4;             // 当前指令地址 下一指令地址
    logic [bit_width-1:0] PCTarget;                // 指令地址转移
    logic [bit_width-1:0] instr;                   // 取指数据

    logic [bit_width-1:0] ram_cin_32bit;               // 要写入 RAM 的数据（32 位）
    logic [bit_width-1:0] ram_dout_32bit;          //  RAM 输出的数据（32 位）

    logic [bit_width-1:0] rd1, rd2, wd3;           // 寄存器堆读／写口
    logic [bit_width-1:0] immExt;                  // 立即数扩展结果
    logic [bit_width-1:0] SrcA, SrcB, ALUResult;   // ALU 输入／输出


    // 拆字段：rs1/rs2/rd/imm31:7
    logic [4:0]  instr_reg_a1   = instr[19:15];    // rs1 索引
    logic [4:0]  instr_reg_a2   = instr[24:20];    // rs2 索引
    logic [4:0]  instr_reg_a3   = instr[11:7];     // rd 索引
    logic [31:7] instr_extd_imm = instr[31:7];     // 用于立即数扩展的字段


    // 指令取值与地址逻辑
    assign instr        = InstrIn;       // 将外部取来的 InstrIn 连接到内部信号 instr
    assign InstrMemAdr  = pc;            // 将 PC 值送给指令存储器


    // 数据存储器接口逻辑
    assign ram_dout_32bit   = DataIn;    // 将外部 DataIn 赋给内部 ram_dout_32bit
    assign DataMemTypes     = 3'b100;     // 固定 4 字节（32 位）访问
    assign DataMemAdr       = ALUResult;   // ALUResult 作为数据存储器地址
    assign DataOut          = ram_cin_32bit; // 寄存器 rd2 的值作为写回存储器的数据
    
    // RAM 读写准备
    assign ram_cin_32bit    = rd2;  // 寄存器堆第二路读出的 rd2 连接到 ram_cin_32bit

    // 模块输出
    assign out0 = ram_dout_32bit;

    ProgramCounter #(
        .bit_width(bit_width)
    ) ProgramCounter(
        .clk        (clk),
        .PcSrc      (PcSrc),
        .pc_in      (PCTarget),
        .pc_out     (pc),
        .pc_outadd4 (pc_add4)
    );
    
    //----------------------- 执行地址转移计算 -----------------------
    adder32 #(
        .N(bit_width)
    ) AddrTransfer(
        .a(pc),
        .b(immExt),
        .cin(0),
        .sum(PCTarget)
    );

    //----------------------- 寄存器堆 -----------------------
    regfile #(
        .bit_width(bit_width)
    ) regheap(
        .clk   (clk),
        .we3   (RegWrite),
        .raddr1(instr_reg_a1),
        .raddr2(instr_reg_a2),
        .rdata1(rd1),
        .rdata2(rd2),
        .waddr3(instr_reg_a3),
        .wdata (wd3)
    );

    //----------------------- 立即数扩展 -----------------------
    extend immExpansion(
        .ImmSrc(ImmSrc),
        .Instr (instr_extd_imm),
        .immExt(immExt)
    );

    //----------------------- 寄存器写入选择 -----------------------
    always_comb begin
        if(ResultSrc) wd3 = ram_dout_32bit;
        else          wd3 = ALUResult;
    end


    //----------------------- ALU B 端口选择 -----------------------
    always_comb begin
        if (ALUSrc)
            SrcB = immExt;
        else
            SrcB = rd2;
    end
    assign SrcA = rd1;

    //----------------------- ALU -----------------------
    ALU #(
        .bit_width(bit_width)
    ) ALU1(
        .ctrl   (ALUControl),
        .a      (SrcA),
        .b      (SrcB),
        .out    (ALUResult),
        .flags (ALU_flags)
    );


endmodule
