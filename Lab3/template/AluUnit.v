module AluUnit(
    input wire RSTn,
    input wire ASel,
    input wire BSel,
    input wire is_sign,
    input wire [4:0] alu_control,
    input wire [31:0] RF_RD1, // source register 1로 부터 읽을 값
	input wire [31:0] RF_RD2, // source register 2로 부터 읽을 값
    input wire [31:0] imm,
    input wire [11:0] pc,
    output wire [31:0] alu_result
);

wire [31:0] alu_input1;
wire [31:0] alu_input2;

if(ASel == 1) begin
    alu_input1 = pc;
end
else begin
    alu_input1 = RF_RD1;
end

if(BSel == 1) begin
    alu_input2 = imm;
end 
else begin
    alu_input2 = RF_RD2;
end

always@(*) begin
    if(RSTn == 1) begin
       if(alu_control == 4'b0000) begin
       // add
       end
       
       if(alu_control == 4'b0001) begin
        // subtract
       end
       
       if(alu_control == 4'b0010) begin
       // AND
       end
       
       if(alu_control == 4'b0011) begin
       // OR
       end
       
       if(alu_control == 4'b0100) begin
       // XOR
       end
       
       if(alu_control == 4'b0101) begin
       // SLL
       end
       
       if(alu_control == 4'b0110) begin
       // SRL
       end 

       if(alu_control == 4'b0111) begin
       // SRA
       end

       if(alu_control == 4'b1000) begin
        // slt
       end

       if(alu_control == 4'b1001) begin 
        // jalr
       end
    end
end

