
module regfile
#(  parameter bit_width = 32,
    parameter adder_bus_size = 5
)
(
    input logic clk,
    input logic we3,                            //写入使能端
    input logic [adder_bus_size - 1:0] raddr1,  //要读取的寄存器地址1
    input logic [adder_bus_size - 1:0] raddr2,  //要读取的寄存器地址2
    input logic [adder_bus_size - 1:0] waddr3,  //写入的寄存器
    input logic [bit_width - 1: 0] wdata,       //写入的数据
    output logic [bit_width - 1: 0] rdata1,     //根据raddr1输出寄存器的值
    output logic [bit_width - 1: 0] rdata2      //根据raddr2输出寄存器的值
);

    logic [bit_width - 1:0] regfile[2 ** adder_bus_size - 1:0];
    
    
    always_ff @( posedge clk) begin 
        if(we3 && waddr3) regfile[waddr3] <= wdata;
        
    end

    // assign regfile[0] = {bit_width{1'b0}};
    assign rdata1 = raddr1 ? regfile[raddr1] :{bit_width{1'b0}};
    assign rdata2 = raddr2 ? regfile[raddr2] :{bit_width{1'b0}};


endmodule
