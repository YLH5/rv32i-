
// @djs top Controller
module Controller #(
    parameter bit_width = 32
) (
    // input  logic                    clk,
    input  logic [6:0]              op,
    input  logic [2:0]              funct3,
    input  logic [6:0]              funct7,
    input  logic [bit_width-1:0]    ALU_flags,
    
    output logic                    RegWrite,
    output logic                    MemWrite,
    output logic                    ALUSrc,
    output logic                    ResultSrc,
    output logic [1:0]              ImmSrc,
    output logic [1:0]              PcSrc,
    output logic [2:0]              ALUControl
);

    // ----------------------------------------------------------------
    // 内部信号声明
    // ----------------------------------------------------------------
    logic           Branch;
    logic [1:0]     ALUOp;

    MainDecoder MainDecoder1(
        .op(op),
        
        .ResultSrc  (ResultSrc),
        .MemWrite   (MemWrite),
        .ALUSrc     (ALUSrc),
        .RegWrite   (RegWrite),
        .Branch     (Branch),
        .ImmSrc     (ImmSrc),
        .ALUOp      (ALUOp)
    );

    ALUDecoder ALUDecoder1(
        .ALUOp      (ALUOp),
        .funct3     (funct3),
        .op_5       (op[5]),
        .funct7_5   (funct7[5]),

        .ALUControl (ALUControl)
    ); 

    PCDecoder u_PCDecoder(
        .Branch(Branch),
        .funct3(funct3),
        .ALU_flags(ALU_flags),
        
        .PcSrc(PcSrc)
    );


endmodule 
