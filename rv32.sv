
/*
 *
 *                  ==<RV32 顶层 CPU 模块>==
 * 模块功能：
 *     实现一个简化的 RISC-V 32 位处理器顶层，涵盖取指、译码、执行、访存和写回五个阶段。
 *     顶层模块负责将子模块（指令存储器 ROM、数据存储器 RAM、控制单元 Controller、
 *     数据通路 Datapath）串联起来，通过控制信号协调各阶段的数据流和时序。
 *
 * 集成子模块：
 *     • InstrMem（ROM）   —— 存放程序指令，只读
 *     • DataMem（RAM32） —— 存放数据，可按字节写入
 *     • Controller       —— 根据 opcode/funct 字段和 ALU 标志生成各类控制信号
 *     • Datapath         —— 完成 PC 更新、寄存器读写、立即数扩展、ALU 运算、访存和写回
 *
 *
 */

module rv32
#(  parameter bit_width = 32
) (
    input  logic                    clk, // 时钟信号：用于同步所有时序逻辑
    output logic [1:0]              Pc,  // PC 更新方式指示（传递给外部或用于调试）
    output logic [bit_width-1:0]    out  // Datapath 输出信号（一般为读自存储器的数据或 ALU 结果）
);
    
    // -------------------- 控制信号 --------------------
    logic                   RegWrite;    // 寄存器写使能
    logic                   ALUSrc;      // ALU B端口操作数来源选择
    logic                   ResultSrc;   // 写回寄存器的数据来源选择
    logic [1:0]             ImmSrc;      // 立即数扩展类型
    logic [1:0]             PcSrc;       // PC 更新方式选择
    logic [2:0]             ALUControl;  // ALU 操作类型编码
    logic [bit_width-1:0]   ALU_flags;   // ALU 运算后产生的状态标志

    // -------------------- 指令存储器接口 --------------------
    logic [bit_width-1:0]   InstrMemOut; // 从指令存储器读出的指令
    logic [bit_width-1:0]   InstrMemAdr; // 供给指令存储器的地址（当前 PC）

    // -------------------- 数据存储器接口 --------------------
    logic                   DataMemWe;   // 数据存储器写使能
    logic [2:0]             DataMemTypes;// 数据存取类型（字节/半字/字）
    logic [bit_width-1:0]   DataMemAdr;  // 数据存储器访问地址
    logic [bit_width-1:0]   DataMemOut;  // 从数据存储器读出的整字数据
    logic [bit_width-1:0]   DataMemIn;   // 写入数据存储器的数据

    // -------------------- 指令字段解析 --------------------
    logic [6:0]             op;          // 指令操作码：InstrMemOut[6:0]
    logic [2:0]             funct3;      // 指令 funct3 字段：InstrMemOut[14:12]
    logic [6:0]             funct7;      // 指令 funct7 字段：InstrMemOut[31:25]

    // 拆分指令字段
    assign op     = InstrMemOut[6:0];      // opcode
    assign funct3 = InstrMemOut[14:12];    // funct3
    assign funct7 = InstrMemOut[31:25];    // funct7

    // 将 PC 控制信号输出给顶层端口
    assign Pc = PcSrc;

    // ==================== 子模块实例化 ====================
    
    // 指令存储器（只读 ROM）
    rom #(
        .bit_width(bit_width)
    ) InstrMem(
        .adr  (InstrMemAdr),  // 地址输入
        .dout (InstrMemOut)   // 数据输出：当前指令
    );

    // 数据存储器（支持按字节写入）
    ram32 #(
        .ADDR_WIDTH(bit_width)
    ) DataMem(
        .clk   (clk),             // 时钟信号
        .we    (DataMemWe),        // 写使能
        .waddr (DataMemAdr),       // 写地址
        .raddr (DataMemAdr),       // 读地址（同地址复用）
        .types (DataMemTypes),     // 访问类型控制

        .cin0  (DataMemIn[7:0]),   // 写入字节 0
        .cin1  (DataMemIn[15:8]),  // 写入字节 1
        .cin2  (DataMemIn[23:16]), // 写入字节 2
        .cin3  (DataMemIn[31:24]), // 写入字节 3

        .dout0 (DataMemOut[7:0]),  // 读出字节 0
        .dout1 (DataMemOut[15:8]), // 读出字节 1
        .dout2 (DataMemOut[23:16]),// 读出字节 2
        .dout3 (DataMemOut[31:24]) // 读出字节 3
    );

    // 控制单元：根据指令字段和 ALU 标志生成控制信号
    Controller #(
        .bit_width(bit_width)
    ) CpuControl(
        .op        (op),          // 操作码
        .funct3    (funct3),      // funct3 字段
        .funct7    (funct7),      // funct7 字段
        .ALU_flags (ALU_flags),   // ALU 生成的标志

        .RegWrite  (RegWrite),    // 寄存器写使能输出
        .MemWrite  (DataMemWe),   // 存储器写使能输出
        .ALUSrc    (ALUSrc),      // ALU 源选择输出
        .ResultSrc (ResultSrc),   // 写回数据来源选择输出
        .ImmSrc    (ImmSrc),      // 立即数扩展类型输出
        .PcSrc     (PcSrc),       // PC 更新方式输出
        .ALUControl(ALUControl)   // ALU 操作类型输出
    );

    // 数据通路：执行指令的六个阶段
    Datapath #(
        .bit_width(bit_width)
    ) U_Datapath(
        .InstrIn      (InstrMemOut),  // 取指阶段：指令输入
        .InstrMemAdr  (InstrMemAdr),  // 取指阶段：PC 地址输出

        .DataIn       (DataMemOut),   // 访存阶段：数据存储器读出
        .DataMemTypes (DataMemTypes), // 访存阶段：数据类型
        .DataMemAdr   (DataMemAdr),   // 访存阶段：地址
        .DataOut      (DataMemIn),    // 访存阶段：写入数据

        .clk          (clk),          // 时钟同步
        .RegWrite     (RegWrite),     // 写回阶段：寄存器写使能
        .ALUSrc       (ALUSrc),       // 执行阶段：ALU 源选择
        .ResultSrc    (ResultSrc),    // 写回阶段：选择写回的数据
        .ImmSrc       (ImmSrc),       // 译码阶段：立即数扩展类型
        .PcSrc        (PcSrc),        // PC 更新方式
        .ALUControl   (ALUControl),   // 执行阶段：ALU 操作类型

        .ALU_flags    (ALU_flags),    // ALU 状态标志回写给控制单元
        .out0         (out)           // Datapath 输出端口映射
    );

endmodule
