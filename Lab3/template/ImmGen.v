module ImmGen(
    input wire [2:0] imm_control
    input wire [31:0] I_MEM_DI
    output wire [31:0] offset
);

always@(*) begin
    if(imm_control == 3'b000) begin
        //U-type
        offset[31:12] = I_MEM_DI[31:12];
        offset[11:0] = 12'b000000000000;
    end

    if(imm_control == 3'b001 ) begin
        // J-type (JAL)
        offset[19] = I_MEM_DI[31];
        offset[18:11] = I_MEM_DI[19:12];
        offset[10] = I_MEM_DI[20];
        offset[9:0] = I_MEM_DI[30:21];
        if(I_MEM_DI[31] == 1) begin
            offset[31:20] = 12'b111111111111;
        end
        else begin
            offset[31:20] = 12'b000000000000;
        end
    end
    
    if(imm_control == 3'b010) begin
        //I-type and JALR() and L-type
    end
    if(imm_control == 3'b011) begin
        //B-type
    end
    if(imm_control == 3'b100) begin
        //S-type
    end
    if(imm_control == 3'b101) begin
        //Shift, SLLI, SRLI, SRAI
    end
end

endmodule