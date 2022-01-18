module AluUnit(
    input wire RSTn,
    input wire [1:0] ASel,
    input wire [1:0] BSel,
    input wire is_sign,
    input wire [4:0] alu_control,
    input wire [31:0] RF_RD1, // source register 1로 부터 읽을 값
	input wire [31:0] RF_RD2, // source register 2로 부터 읽을 값
    input wire [31:0] imm,
    input wire [11:0] pc,
    input wire [11:0] old_pc,
    output wire [31:0] alu_result,
    output wire [1:0] br_control // BrEq,BrLt
);

wire [31:0] alu_input1;
wire [31:0] alu_input2;

reg [31:0] alu_input1_reg;
reg[31:0] alu_input2_reg;

assign alu_input1 = alu_input1_reg;
assign alu_input2 = alu_input2_reg;

always @(*) begin
    if(ASel == 2'b00) begin
        alu_input1_reg = RF_RD1;
    end
    else if(ASel == 2'b01) begin
        alu_input1_reg = pc;
    end
    else if(ASel == 2'b10) begin
        alu_input1_reg = old_pc;
    end

    if(BSel == 2'b00) begin
        alu_input2_reg = RF_RD2;
    end
    else if(BSel == 2'b01) begin
        alu_input2_reg = imm;
    end
    else if(BSel == 2'b10) begin
        alu_input2_reg = 4;
    end
end

reg [31:0] alu_result_reg;
reg [1:0] br_control_reg;
assign alu_result = alu_result_reg;
assign br_control = br_control_reg;


always@(*) begin
    if(RSTn == 1) begin

        if(is_sign) begin
            if(RF_RD1 == RF_RD2) begin
                br_control_reg = 2'b10;
            end 
            else if(RF_RD1 != RF_RD2) begin
                if($signed(RF_RD1) < $signed(RF_RD2)) begin
                    br_control_reg = 2'b01;
                end
                else begin
                    br_control_reg = 2'b00;
                end
            end
        end
        else begin
            if(RF_RD1 == RF_RD2) begin
                br_control_reg = 2'b10;
            end 
            else if(RF_RD1 != RF_RD2) begin
                if(RF_RD1 < RF_RD2) begin
                    br_control_reg = 2'b01;
                end
                else begin
                    br_control_reg = 2'b00;
                end
            end
        end

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