module Control_Unit(
    input wire RSTn,
    input wire [31:0] I_MEM_DI,
    output wire [2:0] imm_control,
    output wire RF_WE,
    output wire D_MEM_WEN,
    output wire [3:0] D_MEM_BE,
    output wire is_sign,
    output wire BSel,
    output wire ASel,
    output wire [4:0] alu_control,
    output wire [2:0] wb_control
);

reg[6:0] opcode;
reg[2:0] func3;
reg[6:0] func7;

//control
reg[6:0] op_LUI;
reg[6:0] op_AUIPC;
reg[6:0] op_JAL;
reg[6:0] op_JALR;
reg[6:0] op_Btype;
reg[6:0] op_Ltype;
reg[6:0] op_Stype;
reg[6:0] op_Itype;
reg[6:0] op_Rtype;

initial begin
    op_LUI <= 7'b0110111;
    op_AUIPC <= 7'b0010111;
    op_JAL <= 7'b1101111;
    op_JALR <= 7'b1100111;
    op_Btype <= 7'b1100011;
    op_Ltype <= 7'b0000011;
    op_Stype <= 7'b0100011;
    op_Itype <= 7'b0010011;
    op_Rtype <= 7'b0110011;
end


always@(*) begin
    if(RSTn==0) begin
        opcode = I_MEM_DI[6:0];
        func3 = I_MEM_DI[14:12];
        func7 = I_MEM_DI[31:25];
        if(opcode == op_Itype) begin
            if(func3 = 3'b101 || func3 = 3'b001) begin
                imm_control
            end
        end
    end
end

endmodule