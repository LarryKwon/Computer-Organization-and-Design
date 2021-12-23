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

assign alu_input1 = (ASel)? pc : RF_RD1;
assign alu_input2 = (BSel)? imm : RF_RD2;

reg [31:0] alu_result_reg;



assign alu_result = alu_result_reg;

always@(*) begin
    if(RSTn == 1) begin
       if(alu_control == 4'b0000) begin
       // add
            if(is_sign) begin
                alu_result_reg = $signed(alu_input1) + $signed(alu_input2);
            end
            else begin
                alu_result_reg = alu_input1 + alu_input2;
            end
       end
       
       if(alu_control == 4'b0001) begin
        // subtract
            alu_result_reg = alu_input1 - alu_input2;
       end
       
       if(alu_control == 4'b0010) begin
       // AND
            alu_result_reg = alu_input1 & alu_input2;
       end
       
       if(alu_control == 4'b0011) begin
       // OR
            alu_result_reg = alu_input1 | alu_input2;
       end
       
       if(alu_control == 4'b0100) begin
       // XOR
            alu_result_reg = alu_input1^alu_input2;
       end
       
       if(alu_control == 4'b0101) begin
       // SLL
            alu_result_reg = alu_input1 << alu_input2;
       end
       
       if(alu_control == 4'b0110) begin
       // SRL
            alu_result_reg = alu_input1 >> alu_input2;
       end 

       if(alu_control == 4'b0111) begin
       // SRA
            alu_result_reg = $signed(alu_input1) >>> alu_input2;
       end

       if(alu_control == 4'b1000) begin
        // slt
            if(is_sign) begin
                if($signed(alu_input1) < $signed(alu_input2)) begin
                    alu_result_reg = 1;
                end
                else begin
                    alu_result_reg = 0;
                end
            end
            else begin
                if(alu_input1 < alu_input2) begin
                    alu_result_reg = 1;
                end
                else begin
                    alu_result_reg = 0;
                end            
            end
       end

       if(alu_control == 4'b1001) begin 
        // jalr
            alu_result_reg = (alu_input1 + alu_input2);
            alu_result_reg[0] = 0;
       end
    end
end

endmodule