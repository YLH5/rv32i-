/* 
 *                      ==<RISCV 32 主译码器>==
 * 模块功能：
 *      根据指令的操作码（op）生成控制信号，分别由ALU和Datapath接收。
 *
 *
 * 输入端口说明：
 *  op      -- 指令操作码
 *          
 *      
 * 输出端口说明：
 *          1、由数据通路模块（Datapath）接收的信号
 *          -- ResultSrc寄存器写入数据来源选择
 *          -- MemWrite：数据存储器写使能
 *          -- ALUSrc：ALU第二操作数来源选择
 *          -- RegWrite：寄存器写使能
 *          -- ImmSrc：立即数扩展类型选择
 *          
 *          2、由PCDecoder模块接收的信号
 *          -- Branch：是否是B-type型指令
 *
 *          3、由ALUDecoder模块接收的信号
 *          -- ALUop：ALU做何种运算
 *                  S/I(Load)-type做加法、B-type做减法，
 *                  R/I(Operations)-type根据funt3功能码判断。
 *
 *
 *        根据操作码（op）区分出R-type、I-type、S-type、B-type、U-type、J-type，
 *        再生成控制信号。
 *
 *        前5个控制信号的详细表示及作用见数据通路文件（Datapath.sv）。
 *        ALUop控制信号的详细表示及作用见ALU译码器文件（ALUDecoder.sv）。
 *
 *
*/

module MainDecoder
(
    input  logic [6:0]      op,

    output logic            ResultSrc,
    output logic            MemWrite,
    output logic            ALUSrc  ,
    output logic            RegWrite,
    output logic            Branch,
    output logic [1:0]      ImmSrc,
    output logic [1:0]      ALUOp
);
    
    // ----------------------------------------------------------------
    // 内部信号声明
    //
    // CtrlSrc  --控制信号集合
    //      CtrlSrc组成格式：
    //      [8]:ResultSrc + [7]:MemWrite + [6]:ALUSrc +
    //      [5]:RegWrite +[4]:Branch+ [3:2]:ImmSrc + [1:0]:ALUOp
    //
    // ----------------------------------------------------------------
    logic [8:0] CtrlSrc;

    assign {ResultSrc, MemWrite, ALUSrc, RegWrite, Branch, ImmSrc, ALUOp} = CtrlSrc;

    always_comb begin
        case (op)
            7'b0110011: CtrlSrc = 9'b0_0_0_1_0_00_10;    //R-type
            7'b0000011: CtrlSrc = 9'b1_0_1_1_0_00_00;    //I-type Load
            7'b0010011: CtrlSrc = 9'b0_0_1_1_0_00_10;    //I-type Operations
            7'b0100011: CtrlSrc = 9'b0_1_1_0_0_01_00;    //S-type
            7'b1100011: CtrlSrc = 9'b0_0_0_0_1_10_01;    //B-type

            default:    CtrlSrc = 9'b0_0_0_0_0_00_00;
        endcase
    end

    // assign ResultSrc    = CtrlSrc[8];
    // assign MemWrite     = CtrlSrc[7];
    // assign ALUSrc       = CtrlSrc[6];
    // assign RegWrite     = CtrlSrc[5];
    // assign Branch       = CtrlSrc[4];
    // assign ImmSrc       = CtrlSrc[3:2];
    // assign ALUOp        = CtrlSrc[1:0];
endmodule 