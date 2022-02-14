module Control_unit (
        input wire [31:0] inst_register,
		input wire RSTn,
        input wire branch,
        input wire [4:0] RF_RA1,
	    input wire [4:0] RF_RA2,

        output reg [2:0] offset_control,

        output reg [3:0] ALU_control,
        output reg ALU_src1,
        output reg [1:0] ALU_src2,
        output reg unsigned_op,
        output reg ALUT_control,
        output reg ALUT_src1,
        output reg ALUT_src2,


        output reg RF_WE_REG,
        output reg WDsrc,
        output reg D_MEM_WEN_REG, 
        output reg [3:0] D_MEM_BE_REG,
        
        output reg [6:0]cur_type,
        output reg [2:0] pcSrc,
        output reg is_flush,
        input reg is_stall,


        input wire valid,
        input reg [6:0] XM_cur_type,
        input reg [4:0] DX_WA,

        
        input wire DX_valid,
        input wire DX_prediction,
        input reg [6:0] DX_cur_type,
        input reg [11:0] DX_target,
        input reg [31:0] ALUT_result

    );
	
    
	reg[2:0] func;
    reg[6:0] func2;

	reg [6:0]R_type;
	reg [6:0]I_type;
	reg [6:0]LW_type;
	reg [6:0]SW_type;
	reg [6:0]B_type;
	reg [6:0]JAL_type;
	reg [6:0]JALR_type;

    initial begin
        JAL_type <= 7'b1101111;
        JALR_type <= 7'b1100111;
        B_type <= 7'b1100011;
        LW_type <= 7'b0000011; 
        SW_type <= 7'b0100011; 
        I_type <= 7'b0010011;
        R_type <= 7'b0110011;
	end

    always @(*) begin
       if(RSTn == 1) begin
            cur_type = inst_register[6:0];
            func = inst_register[14:12];
			func2 = inst_register[31:25];

        //RF_WE_REG
            if(cur_type == SW_type | cur_type == B_type ) begin
                RF_WE_REG = 0;
            end
            else begin
                RF_WE_REG = 1;
            end
            
        //WDsrc
            if(cur_type == LW_type) begin
                WDsrc = 1;
            end
            else begin
                WDsrc = 0;
            end


        //D_MEM_WEN_REG
            if( cur_type == SW_type) begin
                D_MEM_WEN_REG = 0;/////
            end
            else begin
                D_MEM_WEN_REG = 1;
            end

        //D_MEM_BE_REG
            if(cur_type == SW_type | cur_type == LW_type) begin
                D_MEM_BE_REG = 4'b1111;
            end

        //offset_control
            if(cur_type == JAL_type) begin // JAL
                offset_control = 3'b000;
            end
            else if(cur_type == JALR_type | cur_type == LW_type) begin // JALR, LW
                offset_control = 3'b001;
            end
            else if(cur_type == B_type) begin // B-type
                offset_control = 3'b010;
            end
            else if(cur_type == SW_type) begin // SW
                offset_control = 3'b011;
            end
            else if(cur_type == I_type) begin  
                if(func == 3'b001 | func == 3'b101) begin // SLLI,SLRI,SRAI
                    offset_control = 3'b100;
                end
                else begin // other I-type 
                    offset_control = 3'b001;
                end
            end

        //ALU_control
            //+ : LW, SW, ADD, ADDI
            if(  cur_type == SW_type | cur_type == LW_type | ( (cur_type == I_type) & (func == 3'b000) ) | ( (cur_type == R_type) & (func == 3'b000) & (func2 == 7'b0000000) ) ) begin
                ALU_control = 4'b000;
            end
            //- : SUB
            else if( (cur_type == R_type) & (func == 3'b000) & (func2 == 7'b0100000) ) begin
                ALU_control = 4'b001;
            end
            //& : AND, ANDI
            else if( ( (cur_type == R_type) | (cur_type == I_type) ) & (func == 3'b111)  ) begin
                ALU_control = 4'b0010;
            end
            //| : OR, ORI
            else if( ( (cur_type == R_type) | (cur_type == I_type) ) & (func == 3'b110) ) begin
                ALU_control = 4'b0011;
            end
            //XOR, XORI
            else if( ( (cur_type == R_type) | (cur_type == I_type) ) & (func == 3'b100) ) begin
                ALU_control = 4'b0100;
            end
            //SLL, SLLI
            else if( ( (cur_type == R_type) | (cur_type == I_type) ) & (func == 3'b001) ) begin
                ALU_control = 4'b0101;
            end
            //SRL, SRLI
            else if( ( (func == 3'b101) & (func2 == 7'b0000000) ) & ( (cur_type == R_type) | (cur_type == I_type) ) ) begin
                ALU_control = 4'b0110;
            end
            //SRA, SRAI
            else if( ( (func == 3'b101) & (func2 == 7'b0100000) ) & ( (cur_type == R_type) | (cur_type == I_type) ) ) begin
                ALU_control = 4'b0111;
            end
            //SLT, SLTU, SLTI, SLTIU
            else if( ( (func == 3'b011) | (func == 3'b010) ) & ( (cur_type == R_type) | (cur_type == I_type) ) ) begin
                ALU_control = 4'b1000;
            end
            //BEQ
            else if( (cur_type == B_type) & (func == 3'b000) ) begin
                ALU_control = 4'b1001;
            end
            //BNE
            else if( (cur_type == B_type) & (func == 3'b001) ) begin
                ALU_control = 4'b1010;
            end
            //BLT, BLTU
            else if( (cur_type == B_type) & ( (func == 3'b100) | (func == 3'b110) ) ) begin
                ALU_control = 4'b1011;
            end
            //BGE, BGEU
            else if( (cur_type == B_type) & ( (func == 3'b101) | (func == 3'b111) ) ) begin
                ALU_control = 4'b1100;
            end

        //unsigned_op
			if( ( (cur_type == B_type) & ((func == 3'b110) | (func == 3'b111) ) ) | ( ( (cur_type == I_type) | (cur_type == R_type) ) & (func == 3'b011) ) ) begin
                unsigned_op = 1;
            end
            else begin
                unsigned_op = 0;
            end

        //ALU_src1
            if( cur_type == JAL_type | cur_type == JALR_type ) begin
                ALU_src1 = 0;
            end
            else begin
                ALU_src1 = 1;
            end

        //ALU_src2
            if( cur_type == JAL_type | cur_type == JALR_type ) begin
                ALU_src2 = 2'b01;
            end
            else if( (cur_type == I_type) | (cur_type == LW_type) | (cur_type == SW_type ) ) begin
                ALU_src2 = 2'b10;
            end
            else begin
                ALU_src2 = 2'b00;
            end

        //ALUT_control
            if( (cur_type == JAL_type) | (cur_type == B_type) ) begin
                ALUT_control = 1;
            end
            else if ( cur_type == JALR_type ) begin
                ALUT_control = 0;
            end

        //ALUT_src1
            if(cur_type == JALR_type) begin
                ALUT_src1 = 1;
            end
            else begin
                ALUT_src1 = 0;
            end

        //ALUT_src2
            if( cur_type == JAL_type | cur_type == JALR_type | cur_type == B_type ) begin
                ALUT_src2 = 0;
            end
            else begin
                ALUT_src2 = 1;
            end


        //is_flush -
            if( ( (DX_cur_type == B_type) & (DX_valid == 0) & branch ) | ( (DX_cur_type == B_type) & (DX_valid == 1) & (branch != DX_prediction) ) )begin 
                is_flush = 1;
            end
            else begin
                is_flush = 0;
            end
            

        //pcSrc
            if(is_flush) begin // at EX stage, we need to fix pc value = prdeict fail
                // branch correction
                if(branch) begin 
                    pcSrc = 3'b000;
                end
                else if(~branch) begin 
                    pcSrc = 3'b001;
                end
            end
            else if(is_stall) begin 
                if( (DX_cur_type == LW_type) & (DX_WA != 0) & ( (DX_WA == RF_RA1) | (DX_WA == RF_RA2) ) ) begin
                    pcSrc = 3'b100;
                end
                else begin // jump correction
                    
                    pcSrc = 3'b111;    
                end
            end
            else begin 
                if(valid == 0) begin 
                    pcSrc = 3'b101;
                end
                else begin // non first branch instruction -> branch predict by BTB
                    pcSrc = 3'b110;
                end
            end

        //is_hit
            // if( (XM_cur_type == LW_type | XM_cur_type == SW_type)) begin
            //     if(temp)
            // end  
        end 
    end

endmodule

