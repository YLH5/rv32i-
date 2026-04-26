

module extend(

    //00: 选择Instr[31:20]作为立即数
    //01: 选择Instr[31:25],[11:7]作为立即数
    //10: 选择Instr[31],[7],[30:25],[11:8],1'b0作为立即数
    input  logic [1: 0] ImmSrc,   
    input  logic [31:7] Instr,
    output logic [31:0] immExt

);

    always_comb begin
        case (ImmSrc)
            2'b00 :  immExt = {{20{Instr[31]}}, Instr[31:20]};
            2'b01 :  immExt = {{20{Instr[31]}}, Instr[31:25], Instr[11:7]};
            2'b10 :  immExt = {{20{Instr[31]}}, Instr[7], Instr[30:25], Instr[11:8], 1'b0};
            default: immExt = {{20{Instr[31]}}, Instr[31:20]};
        endcase
    end
    
endmodule