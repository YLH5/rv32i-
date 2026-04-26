

/*
 *  指令名   助记符	                          funct3  条件判断规则    
 *  beq	    Branch  Equal	                3'b000	rs1 == rs2 时跳转
 *  bne	    Branch  Not Equal	            3'b001	rs1 != rs2 时跳转
 *  blt	    Branch  Less Than	            3'b100	有符号比较 rs1 < rs2 时跳转
 *  bge	    Branch  Greater Equal	        3'b101	有符号比较 rs1 >= rs2 时跳转
 *  bltu	Branch  Less Than Unsigned	    3'b110	无符号比较 rs1 < rs2 时跳转
 *  bgeu	Branch  Greater Equal Unsigned	3'b111	无符号比较 rs1 >= rs2 时跳转
 *
 *
 *  PcSrc[1:0]—— 程序计数器更新方式
 *               00：PC <- 0（复位）
 *               01：PC <- PC + 4（顺序执行）
 *               10：PC <- pc_in（跳转/分支）
 *               11：PC <- PC（单指令循环）
*/
module PCDecoder #(
    parameter bit_width = 32
)(
    input  logic                 Branch,
    input  logic [2:0]           funct3,
    input  logic [bit_width-1:0] ALU_flags,

    output logic [1:0]           PcSrc
);

    // ---------------------------------------------------------
    //
    // 内部信号
    //
    // 分离标志寄存器标志位:    Z 零标志位          N 负标志位 
    //                       C 进位/借位标志位    V 溢出标志位
    //
    // ---------------------------------------------------------
    logic Z ;
    logic N ;
    logic C ;
    logic V ;
    assign Z = ALU_flags[0];
    assign N = ALU_flags[1];
    assign C = ALU_flags[2];
    assign V = ALU_flags[3];
    
    logic [1:0] pcsa;
    always_comb begin
        if(Branch) begin
            case (funct3)
                //beq  rs1 == rs2
                3'b000: 
                    pcsa = (Z) ? 2'b10 : 2'b01;
                //bne rs1 != rs2
                3'b001:
                    pcsa = (~Z) ? 2'b10 : 2'b01;
                //blt 有符号比较 rs1 < rs2
                3'b100:
                    pcsa = (N ^ V) ? 2'b10 : 2'b01;
                //bge 有符号比较 rs1 >= rs2
                3'b101:
                    pcsa = (~(N ^ V)) ? 2'b10 : 2'b01;      
                //bltu 无符号比较 rs1 < rs2
                3'b110:
                    pcsa = (~C) ? 2'b10 : 2'b01;
                //bgeuv无符号比较 rs1 >= rs2
                3'b111:
                    pcsa = (C) ? 2'b10 : 2'b01;

                default: 
                    pcsa = 2'b01;
            endcase

        end
        else
            pcsa = 2'b01;
  end
    assign PcSrc = pcsa;
endmodule



