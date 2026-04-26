/* 
 *                      ==<RISCV 32 ALU译码器>==
 * 模块功能：
 *      根据 ALUOp、funct3、op[5]、funct7[5] 生成 ALU 控制信号。
 *
 *      注意：
 *          *表示未支持功能
 *
 *
 * 输入端口说明： 
 *
 *  ALUOp   -- 主译码器生成的操作类型码：
 *              00：I-type（Load）或 S-type（地址计算需加法）
 *              01：B-type（分支比较需减法）
 *              10：R-type 或 I-type(Operations)（运算需根据 funct3/funct7 细化）
 *              11：保留未用
 *
 *  funct3  -- 区分运算类型：
 *              000：ADD/ADDI 或 SUB（需结合 funct7[5] 判断）
 *              001：SLL/SLLI   *
 *              010：SLT/SLTI   
 *              011：SLTU/SLTIU
 *              100：XOR/XORI   
 *              101：SRL/SRLI 或 SRA/SRAI（需结合 funct7[5] 判断）  *
 *              110：OR/ORI
 *              111：AND/ANDI
 *
 *  op[5]   -- 辅助区分 R-type 和 I-type(Operations) 运算指令：
 *              0：I-type(Operations) 运算指令（op[6:0]=7'b0010011）
 *              1：R-type 指令（op[6:0]=7'b0110011）
 *
 *  funct7[5] 
 *          -- 细化操作类型：
 *              0：ADD / SRL* / SRLI*
 *              1：SUB /SRA* / SRAI*
 *              注：仅在以下情况有效：
 *                  - funct3=000（ADD/SUB）
 *                  - funct3=001 或 101（移位类型）
 *
 * 输出端口说明： 
 *
 *  ALUControl
 *          -- ALU 控制信号，详见算术模块文件（ALU.sv）
 *
 * 示例：
 * - funct3=000, funct7[5]=0 → ALUControl=ADD (3'b000)
 * - funct3=000, funct7[5]=1 → ALUControl=SUB (3'b001)
 * - funct3=001, funct7[5]=0 → ALUControl=SLL (3'b101)
 * - funct3=101, funct7[5]=1 → ALUControl=SRA (3'b111)
 */



module ALUDecoder(
    input  logic [1:0]  ALUOp,
    input  logic [2:0]  funct3,
    input  logic        op_5,
    input  logic        funct7_5,

    output logic [2:0]  ALUControl
);

    
    always_comb begin

        if (ALUOp[1] & ~ALUOp[0]) begin
            case (funct3)
            
                // ADD/ADDI或SUB，(op[5] & funct7[5])区分加法还是减法运算
                3'b000: 
                    ALUControl = (op_5 & funct7_5) ? 3'b001 : 3'b000;

                // SLL/SLLI *
                // 3'b001: ;

                // SLT/SLTI
                3'b010: ALUControl = 3'b010;

                // SLTU/SLTIU
                3'b011: ALUControl = 3'b011;

                // XOR/XORI
                3'b100: ALUControl = 3'b100;

                // SRL/SRLI *
                // 3'b101: ;

                // OR/ORI
                3'b110: ALUControl = 3'b110;

                // AND/ANDI
                3'b111: ALUControl = 3'b111;
                
                //默认加法
                default: ALUControl = 3'b000;
            endcase
        end

        else if(~ALUOp[1] & ALUOp[0]) // B-type: SUB
            ALUControl = 001;

        else if(~(|ALUOp[1:0])) // Load/Store: ADD
            ALUControl = 000;
        else                    //默认加法
            ALUControl = 000;
    end
endmodule 