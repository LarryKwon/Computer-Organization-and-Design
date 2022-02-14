module ImmGen(
    input wire RSTn,
    input wire [2:0] imm_control,
    input wire [31:0] I_MEM_DI,
    output wire [31:0] imm
);

reg[31:0] imm_reg;
assign imm = imm_reg;

always@(*) begin
    if(RSTn == 1) begin
        if(imm_control == 3'b000) begin
            //U-type
            imm_reg[31:12] = I_MEM_DI[31:12];
            imm_reg[11:0] = 12'b000000000000;
        end

        if(imm_control == 3'b001 ) begin
            // J-type (JAL)
            imm_reg[0] = 0;
            imm_reg[20] = I_MEM_DI[31];
            imm_reg[19:12] = I_MEM_DI[19:12];
            imm_reg[11] = I_MEM_DI[20];
            imm_reg[10:1] = I_MEM_DI[30:21];
            if(I_MEM_DI[31] == 1) begin
                imm_reg[31:20] = 12'b111111111111;
            end
            else begin
                imm_reg[31:20] = 12'b000000000000;
            end
        end
        
        if(imm_control == 3'b010) begin
            //I-type and JALR() and L-type
            imm_reg[11:0] = I_MEM_DI[31:20];
            if(I_MEM_DI[31]==1) begin
                imm_reg[31:12] = 20'b11111111111111111111;
            end
            else begin
                imm_reg[31:12] = 20'b00000000000000000000;
            end
        end
        if(imm_control == 3'b011) begin
            //B-type
            imm_reg[0] = 0;
            imm_reg[4:1] = I_MEM_DI[11:8];
            imm_reg[10:5] = I_MEM_DI[30:25];
            imm_reg[11] = I_MEM_DI[7];
            imm_reg[12] = I_MEM_DI[31];
            if(I_MEM_DI[31] == 1) begin
                imm_reg[31:13] = 20'b11111111111111111111;
            end
            else begin
                imm_reg[31:12] = 20'b00000000000000000000;
            end
        end
        if(imm_control == 3'b100) begin
            //S-type
            imm_reg[4:0] = I_MEM_DI[11:7];
            imm_reg[11:5] = I_MEM_DI[31:25];
            if(I_MEM_DI[31] == 1) begin
                imm_reg[31:12] = 20'b11111111111111111111;
            end
            else begin
                imm_reg[31:12] = 20'b00000000000000000000;
            end
        end
        if(imm_control == 3'b101) begin
            //Shift, SLLI, SRLI, SRAI
            imm_reg[4:0] = I_MEM_DI[24:20];
            imm_reg[31:5] = 27'b000000000000000000000000000;
        end
    end
end

endmodule