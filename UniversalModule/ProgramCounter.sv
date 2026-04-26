/*
 * ProgramCounter(程序计数模块)
 * 
 *      指定当前执行指令地址，这个模块在初始状态输出值是0，
 *      但是一个时钟周期后就会变为高阻态，如果要从0执行代码，请在模块启动初期
 *      就把PcSrc信号置为1。
 */

module ProgramCounter
#(  parameter bit_width = 32,
    parameter inc       = 4
)
(
    input logic  clk,
    //00：复位，01：加addend个地址(默认为4)，10：读取将地址修改为pc_in地址, 11：不修改地址
    input logic  [1:0]             PcSrc  = 0,                
    input logic  [bit_width - 1:0] addend = inc, //地址加多少个
    input logic  [bit_width - 1:0] pc_in,        //地址输入，PcSrc为10b有效
    output logic [bit_width - 1:0] pc_out,       //地址输出
    output logic [bit_width - 1:0] pc_outadd4   //下一地址输出

);


    logic [bit_width - 1:0] pc = 0, pcNext, pcplusN;

    always_comb begin
        case (PcSrc)
            2'b00: pcNext = 0;
            2'b01: pcNext = pcplusN;
            2'b10: pcNext = pc_in; 
            2'b11: pcNext = pc;
            default: pcNext = 0;
        endcase
    end
    
    always_ff @(posedge clk) begin
        pc <= pcNext;
    end
    assign pc_out = pc;

    adder32 addr(
        .a(pc),
        .b(addend),
        .cin(0),
        .sum(pcplusN)
    );
    assign pc_outadd4 = pcplusN;

endmodule


// module top(
//     input logic clk,
//     input logic [1:0] PcSrc,
//     input logic [31:0] addend,
//     input logic [31:0] pc_in,
//     output logic [31:0] pc_out
// );

//     ProgramCounter
//     #(  .bit_width(32))
//     pc1(
//         .clk(clk),
//         .PcSrc(PcSrc),
//         // .addend(addend),
//         .pc_in(pc_in),
//         .pc_out(pc_out)
//     );
// endmodule