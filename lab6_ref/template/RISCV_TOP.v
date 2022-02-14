module RISCV_TOP (
	//General Signals
	input wire CLK,
	input wire RSTn,

	//I-Memory Signals
	output wire I_MEM_CSN,
	input wire [31:0] I_MEM_DI,//input from IM
	output reg [11:0] I_MEM_ADDR,//in byte address

    input reg [2:0] pcSrc,
    input reg is_flush,
    output reg branch,
    output wire valid,
    

	//D-Memory Signals
	output wire D_MEM_CSN,
	input wire [31:0] D_MEM_DI,
	output wire [31:0] D_MEM_DOUT,
	output wire [11:0] D_MEM_ADDR,//in word address
	output wire D_MEM_WEN,
	output wire [3:0] D_MEM_BE,

	//RegFile Signals
	output wire RF_WE,
	output wire [4:0] RF_RA1,
	output wire [4:0] RF_RA2,
	output wire [4:0] RF_WA1,
	input wire [31:0] RF_RD1,
	input wire [31:0] RF_RD2,
	output wire [31:0] RF_WD,
	output wire HALT,                   // if set, terminate program
	output reg [31:0] NUM_INST,         // number of instruction completed
	output wire [31:0] OUTPUT_PORT,      // equal RF_WD this port is used for test

    //control
    output reg [31:0] FD_inst_register,
    

    input reg [2:0] offset_control,
    input reg [3:0] ALU_control,
    input reg ALU_Src1,
    input reg [1:0] ALU_Src2,
    input reg unsigned_op,
    input reg ALUT_control,
    input reg ALUT_src1,
    input reg ALUT_src2,
    input reg RF_WE_REG,
    input reg WDsrc,
    input reg D_MEM_WEN_REG,
    input reg [3:0] D_MEM_BE_REG,

    input reg [6:0] cur_type,
    

    //forwarding unit
    output reg [4:0] XM_WA,
    output reg [4:0] DX_RA1,
    output reg [4:0] DX_RA2,
    output reg XM_RF_WE,
    output reg MB_RF_WE,
    output reg [4:0] MB_WA,
    output reg [4:0] DX_WA,

    input reg [2:0] RD1_src,
    input reg [2:0] RD2_src,
    input reg [2:0] ID1_src,

    inout reg is_stall,
    

    output reg [6:0] XM_cur_type,
    output reg DX_prediction,
    output reg DX_valid,
    output reg [6:0] DX_cur_type,
    output reg [11:0] DX_target,
    output reg [31:0] ALUT_result
	);

    //connect csn signal
	assign I_MEM_CSN = ~RSTn;
	assign D_MEM_CSN = ~RSTn;

    reg [4:0] ID_RF_RD1;
    

    //cache register
    reg is_hit;
    reg [31:0] Cache_RD;

    initial begin
        is_hit <= 1;
    end
    
    reg [11:0] pc;
    initial begin
        pc <= 0;
    end

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

	initial begin
		NUM_INST <= 0;
	end


    //IF/ID register
	reg [11:0] FD_pc;
	
    initial begin
        FD_inst_register <= 32'h00000013;
        FD_pc <= 0;
    end

    // ID/EX register
	reg [31:0] DX_RD1;
	reg [31:0] DX_RD2;
	reg [11:0] DX_pc;
	reg [31:0] DX_offset;
    reg DX_RF_WE;
    reg DX_WDsrc;
    reg DX_D_MEM_WEN;
    reg [3:0] DX_D_MEM_BE;

    reg DX_ALUT_src1;
    reg DX_ALUT_src2;
    reg [3:0] DX_ALU_control;
    reg DX_ALU_src1;
    reg [1:0] DX_ALU_src2;
    reg DX_unsigned_op;
    reg [31:0] DX_inst_register;
    reg [31:0] DX_ALUT_result;

    initial begin
        DX_RF_WE <= 0;
        DX_D_MEM_WEN <= 1;
        DX_cur_type <= I_type;
        DX_pc <= 0;
        DX_offset <= 0;
        DX_RA1 <= 0;
        DX_RA2 <= 0;
        DX_WA <= 0;
        DX_inst_register <= 32'h00000013;
    end
    
    // EX/MEM register
	reg [31:0] XM_ALU_result;

	reg [31:0] XM_RD2;
	reg [11:0] XM_pc;
    
    reg XM_WDsrc;
    reg XM_D_MEM_WEN;

    reg [3:0] XM_D_MEM_BE;
    reg [31:0] XM_inst_register;


    initial begin
        XM_D_MEM_WEN <= 1;
        XM_RF_WE <= 0;
        XM_cur_type <= I_type;
        XM_inst_register <= 32'h00000013;

    end

    // MEM/WB register
    reg [31:0] MB_D_MEM_RD;
    reg [31:0] MB_ALU_result;
    reg MB_WDsrc;
    reg [31:0] MB_inst_register;


    initial begin
        MB_RF_WE <= 0;
        MB_inst_register <= 32'h00000013;
    end

    //instant register
    reg [31:0] offset;
    

    reg [31:0] ALU_result;

    reg terminate_flag;


    //control unit 
    Control_unit control_unit (
		.inst_register 	(FD_inst_register),
		.RSTn			(RSTn),
		.branch         (branch),
        .offset_control (offset_control),
        
        .ALU_control	(ALU_control),
        .ALU_src1       (ALU_Src1),
        .ALU_src2       (ALU_Src2),
        .unsigned_op    (unsigned_op),
        .ALUT_control   (ALUT_control),
        .ALUT_src1      (ALUT_src1),
        .ALUT_src2      (ALUT_src2),
        .RF_WE_REG      (RF_WE_REG),
        .WDsrc          (WDsrc),
        .D_MEM_WEN_REG  (D_MEM_WEN_REG),
        .D_MEM_BE_REG   (D_MEM_BE_REG),
        .cur_type       (cur_type),
        .is_flush       (is_flush),
        .pcSrc          (pcSrc),
        .XM_cur_type    (XM_cur_type),
        .DX_WA          (DX_WA),
        .valid          (valid),
        .DX_valid       (DX_valid),
        .DX_prediction  (DX_prediction),
        .DX_cur_type    (DX_cur_type),
        .DX_target      (DX_target),
        .is_stall       (is_stall)
	);


    //forwarding unit - finish
    Forwarding_unit forwarding_unit (
        .RSTn           (RSTn),
        .RF_RA1         (RF_RA1),
        .RF_RA2         (RF_RA2),
        
        .DX_WA          (DX_WA),
        .XM_WA          (XM_WA),
        .MB_WA          (MB_WA),

        .DX_RF_WE       (DX_RF_WE),
        .XM_RF_WE       (XM_RF_WE),
        .MB_RF_WE       (MB_RF_WE),

        .DX_cur_type    (DX_cur_type),
        
        .RD1_src        (RD1_src),
        .RD2_src        (RD2_src),
        .ID1_src        (ID1_src),

        .is_stall       (is_stall),

        .XM_cur_type    (XM_cur_type),
        .cur_type       (cur_type)
    );
    
    ////////////////////////////////////////////////////////////////
    ////////////////////      IF stage     /////////////////////////
    ////////////////////////////////////////////////////////////////
    
    
    reg [14:0] BTB [5000:0];
    
    reg [15:0] index;
    initial begin
        index <= 0;
        for(index = 0; index < 5001; index=index+1) begin
            BTB[index] <= 0;
        end
    end

    assign I_MEM_ADDR = pc & (12'hFFF);
    assign valid = BTB[pc][0];

   
    always @(posedge CLK) begin
        if(RSTn) begin
            if(is_hit) begin
                if(pcSrc == 3'b000) begin 
                    pc <= BTB[DX_pc][14:3];
                end
                else if(pcSrc == 3'b001) begin 
                    pc <= DX_pc + 4;
                end
                else if(pcSrc == 3'b100) begin
                    pc <= pc;
                end
                else if(pcSrc == 3'b101) begin
                    pc <= pc + 4;
                end
                else if(pcSrc == 3'b110) begin // branch instruction
                    if(BTB[pc][2] == 1) begin //T로 예측
                        pc <= BTB[pc][14:3];
                    end
                    else if(BTB[pc][2] == 0) begin //NT로 예측
                        pc <= pc + 4;
                    end
                end
                else if(pcSrc == 3'b111) begin //jalr/jal instruction
                    if( (DX_cur_type == LW_type) & (DX_WA != 0) & ( (DX_WA == RF_RA1) | (DX_WA == RF_RA2) ) ) begin
                        pc <= pc;
                    end
                    else begin
                        pc <= ALUT_result;
                    end
                end
            end
        end
    end

//

//BTB update
    always @(*) begin
        if(DX_cur_type == B_type)begin //branch의 EX stage에서 operation
            if(DX_valid == 0) begin // branch가 처음 들어온거면
                BTB[DX_pc][14:3] = DX_ALUT_result; // target 넣어주고
                BTB[DX_pc][0] = 1; // valid를 1로 바꿔줌

                if(branch) begin //Taken인데 not taken으로 예측한 경우
                    BTB[DX_pc][2:1] = BTB[DX_pc][2:1] + 1;
                end
            end
            else begin // branch가 처음 들어온 것이 아니면
                if(is_flush) begin // branch 예측이 틀린경우
                    if(branch) begin //Taken인데 not taken으로 예측한 경우
                        if(BTB[DX_pc][2:1] != 2'b11) begin // state update
                            BTB[DX_pc][2:1] = BTB[DX_pc][2:1] + 1;
                        end
                    end
                    else begin //not taken인데 taken으로 예측한 경우
                        if(BTB[DX_pc][2:1] != 2'b00) begin // state update
                            BTB[DX_pc][2:1] = BTB[DX_pc][2:1] - 1;
                            
                        end
                    end
                end
                else begin // branch 예측이 맞은경우
                    if(BTB[DX_pc][2] == 1) begin //T인걸 맞춘경우
                        if(BTB[DX_pc][2:1] != 2'b11) begin // state update
                            BTB[DX_pc][2:1] = BTB[DX_pc][2:1] + 1;
                        end
                    end
                    else begin //NT인걸 맞춘경우 
                        if(BTB[DX_pc][2:1] != 2'b00) begin // state update
                            BTB[DX_pc][2:1] = BTB[DX_pc][2:1] - 1;
                        end
                    end
                end
            end
        end
    end
//

    always @(posedge CLK) begin
        if(RSTn) begin
            if(is_hit) begin
                if(is_flush) begin
                    FD_inst_register <= 32'h00000013;
                end
                else if(is_stall) begin 
                    if( ( (DX_cur_type == LW_type) & (DX_WA != 0) & ( (DX_WA == RF_RA1) | (DX_WA == RF_RA2) ) ) ) begin
                        FD_inst_register <= FD_inst_register;
                        // FD_pc <= pc;
                    end
                    else begin
                        FD_inst_register <= 32'h00000013;
                    end
                end
                else begin
                    FD_inst_register <= I_MEM_DI;
                    FD_pc <= pc;
                end
            end
        end
    end

	////////////////////////////////////////////////////////////////
    ////////////////////      ID stage     /////////////////////////
    ////////////////////////////////////////////////////////////////

    assign RF_RA1 = FD_inst_register[19:15];
    assign RF_RA2 = FD_inst_register[24:20];
    assign cur_type = FD_inst_register[6:0];

//make offset
    always@(*) begin
        if(RSTn) begin
            if(offset_control == 3'b000) begin // JAL
                offset[0] = 1'b0;
                offset[4:1] = FD_inst_register[24:21];
                offset[10:5] = FD_inst_register[30:25];
                offset[11] = FD_inst_register[20];
                offset[19:12] = FD_inst_register[19:12];
                if(FD_inst_register[31] == 1'b0) begin
                    offset[31:20] = 12'b000000000000;
                end 
                else begin
                    offset[31:20] = 12'b111111111111;
                end
            end
            else if(offset_control == 3'b001) begin // I-type, JALR, LW
                offset[11:0] = FD_inst_register[30:20];
                if(FD_inst_register[31] == 1'b0) begin
                    offset[31:11] = 21'b000000000000000000000;
                end 
                else begin
                    offset[31:11] = 21'b111111111111111111111;
                end
            end
            else if(offset_control == 3'b010) begin // B-type
                offset[0] = 1'b0;
                offset[4:1] = FD_inst_register[11:8];
                offset[10:5] = FD_inst_register[30:25];
                offset[11] = FD_inst_register[7];
                if(FD_inst_register[31] == 1'b0) begin
                    offset[31:12] = 20'b00000000000000000000;
                end 
                else begin
                    offset[31:12] = 20'b11111111111111111111;
                end
            end
            else if(offset_control == 3'b011) begin // SW
                offset[0] = FD_inst_register[7];
                offset[4:1] = FD_inst_register[11:8];
                offset[10:5] = FD_inst_register[30:25];
                if(FD_inst_register[31] == 1'b0) begin
                    offset[31:11] = 21'b000000000000000000000;
                end 
                else begin
                    offset[31:11] = 21'b111111111111111111111;
                end
            end
            else if(offset_control == 3'b100) begin // SLLI,SLRI,SRAI
                offset[4:0] = FD_inst_register[24:20];
                offset[31:5] = 27'b000000000000000000000000000;
            end
        end
    end
//    
    always @(posedge CLK) begin
        if(RSTn) begin
            if(is_hit) begin
                if(is_flush) begin
                    DX_RF_WE <= 0;
                    DX_D_MEM_WEN <= 1;
                    DX_D_MEM_BE <= 4'b0000;
                    DX_WA <= 0;
                    DX_inst_register <= 32'h00000013;
                    DX_ALU_control <= 4'b0000;
                    DX_cur_type <= I_type;
                    DX_RA1 <= 0;
                    DX_RA2 <= 0;
                    DX_RD1 <= 0;
                    DX_RD2 <= 0;
                    DX_target <= 0;
                    DX_valid <= 0;
                    DX_prediction <= 0;
                end
                else if(is_stall & ( (DX_cur_type == LW_type) & (DX_WA != 0) & ( (DX_WA == RF_RA1) | (DX_WA == RF_RA2) ) ) )begin
                    DX_RF_WE <= 0;
                    DX_D_MEM_WEN <= 1;
                    DX_D_MEM_BE <= 4'b0000;
                    DX_WA <= 0;
                    DX_inst_register <= 32'h00000013;           
                    DX_cur_type <= I_type;
                    DX_ALU_control <= 4'b0000;
                    DX_RA1 <= 0;
                    DX_RA2 <= 0;
                    DX_RD1 <= 0;
                    DX_RD2 <= 0;
                    DX_target <= 0;
                    DX_valid <= 0;
                    DX_prediction <= 0;
                end
                else begin

                //data path
                    DX_target <= BTB[FD_pc][14:3]; 

                //DX_RD1
                    if(RD1_src == 3'b000) begin
                        DX_RD1 <= ALU_result;
                    end
                    else if(RD1_src == 3'b001) begin
                        DX_RD1 <= Cache_RD;
                    end
                    else if(RD1_src == 3'b010) begin
                        DX_RD1 <= XM_ALU_result;
                    end
                    else if(RD1_src == 3'b011) begin
                        DX_RD1 <= RF_WD;
                    end
                    else if(RD1_src == 3'b100) begin
                        DX_RD1 <= RF_RD1;
                    end
                //   
                //DX_RD2
                    if(RD2_src == 3'b000) begin
                        DX_RD2 <= ALU_result;
                    end
                    else if(RD2_src == 3'b001) begin
                        DX_RD2 <= Cache_RD;
                    end
                    else if(RD2_src == 3'b010) begin
                        DX_RD2 <= XM_ALU_result;
                    end
                    else if(RD2_src == 3'b011) begin
                        DX_RD2 <= RF_WD;
                    end
                    else if(RD2_src == 3'b100) begin
                        DX_RD2 <= RF_RD2;
                    end
                //    
                    DX_pc <= FD_pc;
                    DX_offset <= offset;
                    DX_RA1 <= RF_RA1;
                    DX_RA2 <= RF_RA2;
                    DX_WA <= FD_inst_register[11:7];
                    DX_cur_type <= cur_type;

                    //control path
                //about alu    
                    DX_ALU_src1 <= ALU_Src1;
                    DX_ALU_src2 <= ALU_Src2;
                    DX_ALU_control <= ALU_control;
                    DX_unsigned_op <= unsigned_op;

                    DX_ALUT_src1 <= ALUT_src1;
                    DX_ALUT_src2 <= ALUT_src2;

                    DX_ALUT_result <= ALUT_result;
                //
                    DX_RF_WE <= RF_WE_REG;
                    DX_WDsrc <= WDsrc;
                    DX_D_MEM_WEN <= D_MEM_WEN_REG;
                    DX_D_MEM_BE <= D_MEM_BE_REG;

                    DX_inst_register <= FD_inst_register; 

                    DX_prediction <= BTB[FD_pc][2]; 
                    DX_valid <= BTB[FD_pc][0]; 

                end
            end
        end
    end

	////////////////////////////////////////////////////////////////
    ////////////////////      EX stage     /////////////////////////
    ////////////////////////////////////////////////////////////////

    //----------------------------ALU-----------------------------------------
    wire signed [31:0] ALU_input1;
    wire signed [31:0] ALU_input2;
    
    assign ALU_input1 = (DX_ALU_src1) ? DX_RD1 : DX_pc;
    assign ALU_input2 = (DX_ALU_src2 == 2'b00) ? DX_RD2 : ( (DX_ALU_src2 == 2'b01) ? 4 : DX_offset );  

    always @(*) begin
        branch = 0;
        //+ : LW, SW, ADD, ADDI
        if(DX_ALU_control == 4'b0000) begin
            ALU_result = ALU_input1 + ALU_input2;
        end
        //- : SUB
        else if(DX_ALU_control == 4'b0001) begin
            ALU_result = ALU_input1 - ALU_input2;
        end
        //& : AND, ANDI
        else if(DX_ALU_control == 4'b0010) begin
            ALU_result = ALU_input1 & ALU_input2;
        end
        //| : OR, ORI
        else if(DX_ALU_control == 4'b0011) begin
            ALU_result = ALU_input1 | ALU_input2;
        end
        //XOR, XORI
        else if(DX_ALU_control == 4'b0100) begin
            ALU_result = (ALU_input1&(~ALU_input2))|((~ALU_input1)&ALU_input2);
        end
        //SLL, SLLI
        else if(DX_ALU_control == 4'b0101) begin
            ALU_result = ALU_input1 << ALU_input2 ;
        end
        //SRL, SRLI
        else if(DX_ALU_control == 4'b0110) begin
            ALU_result = ALU_input1 >> ALU_input2;
        end
        //SRA, SRAI
        else if(DX_ALU_control == 4'b0111) begin
            ALU_result = $signed(ALU_input1) >>> ALU_input2;
        end
        //SLT, SLTU, SLTI, SLTIU
        else if(DX_ALU_control == 4'b1000) begin
            if(DX_unsigned_op) begin
                if( $unsigned(ALU_input1) < $unsigned(ALU_input2) ) begin
                    ALU_result = 1;
                end
                else begin
                    ALU_result = 0;
                end
            end
            else begin
                if( ALU_input1 < ALU_input2 ) begin
                    ALU_result = 1;
                end
                else begin
                    ALU_result = 0;
                end
            end
        end
        //BEQ
        else if(DX_ALU_control == 4'b1001) begin
            if( ALU_input1 == ALU_input2 ) begin
                branch = 1;
            end
            else begin
                branch = 0;
            end
            ALU_result = branch;
        end
        //BNE
        else if(DX_ALU_control == 4'b1010) begin
            if( ALU_input1 != ALU_input2 ) begin
                branch = 1;
            end
            else begin
                branch = 0;
            end
            ALU_result = branch;
        end
        //BLT,BLTU
        else if(DX_ALU_control == 4'b1011) begin
            if(DX_unsigned_op) begin //BLTU
                if( $unsigned(ALU_input1) < $unsigned(ALU_input2) ) begin
                    branch = 1;
                end
                else begin
                    branch = 0;
                end
                ALU_result = branch;
            end
            else begin // BLT
                if( ALU_input1 < ALU_input2 ) begin
                    branch = 1;
                end
                else begin
                    branch = 0;
                end
                ALU_result = branch;
            end
        end
        //BGE,BGEU
        else if(DX_ALU_control == 4'b1100) begin
            if(DX_unsigned_op) begin
                if( $unsigned(ALU_input1) >= $unsigned(ALU_input2) ) begin
                    branch = 1;
                end
                else begin
                    branch = 0;
                end
                ALU_result = branch;
            end
            else begin
                if( ALU_input1 >= ALU_input2 ) begin
                    branch = 1;
                end
                else begin
                    branch = 0;
                end
                ALU_result = branch;
            end
        end
    end

    //-----------------------ALU_T operation------------------------------------
    wire signed [31:0]ALUt_input1;
    wire signed [31:0]ALUt_input2;
    

    assign ALUt_input1 = (ALUT_src1) ? ( (ID1_src == 3'b100) ? RF_RD1 : ID_RF_RD1) : FD_pc;
    assign ALUt_input2 = (ALUT_src2) ? 4 : offset;

    always @(*) begin
    //Jal, branch
        if(ALUT_control) begin
            ALUT_result = ALUt_input1 + ALUt_input2;
        end
        //Jalr
        else begin
            ALUT_result = (ALUt_input1 + ALUt_input2) & 32'hfffffffe;
        end
    end

    always @(posedge CLK) begin
        if(RSTn) begin
            if(is_hit) begin
                //data path
                XM_ALU_result <= ALU_result;
                XM_WA <= DX_WA;
                XM_RD2 <= DX_RD2;
                XM_pc <= DX_pc;
                

                //control path
                XM_RF_WE <= DX_RF_WE; 
                XM_WDsrc <= DX_WDsrc;
                XM_D_MEM_WEN <= DX_D_MEM_WEN;
                XM_D_MEM_BE <= DX_D_MEM_BE;
                XM_cur_type <= DX_cur_type;
                XM_inst_register <= DX_inst_register;
            end
        end
    end

    ////////////////////////////////////////////////////////////////
    ////////////////////     ^^Cache^^     /////////////////////////
    ////////////////////////////////////////////////////////////////

    reg [133:0] Cache [7:0];
    reg [11:0] D_MEM_ADDR_REG;
    reg [4:0] i;

    initial begin
        for(i = 0; i < 8; i=i+1) begin
            Cache[i] <= 0;
        end
    end

    wire [11:0] temp_D_MEM_ADDR;
    wire [2:0] idx;
    wire cache_valid;
    wire [4:0] tag;
    wire [1:0] BO;
    reg [1:0] temp_BO;


    initial begin
        temp_BO = 2'b00;
    end

	assign temp_D_MEM_ADDR = (XM_ALU_result) & (16'h3FFF);
	
    assign tag = temp_D_MEM_ADDR[11:7];
    assign idx = temp_D_MEM_ADDR[6:4];
    assign BO = temp_D_MEM_ADDR[3:2];
    assign cache_valid = Cache[idx][128];

    //determine whether cache miss or hit;
    always @(*) begin
        if( (tag != Cache[idx][133:129] | cache_valid == 0) & (XM_cur_type == LW_type | XM_cur_type == SW_type) ) begin
            is_hit = 0;
        end
        else begin
            is_hit = 1;
        end
    end

    

    //Load hit
    always @(*) begin
        if(XM_cur_type == LW_type & is_hit) begin
            if(BO == 2'b00) begin
                Cache_RD = Cache[idx][31:0];
            end
            else if(BO == 2'b01) begin
                Cache_RD = Cache[idx][63:32];
            end
            else if(BO == 2'b10) begin
                Cache_RD = Cache[idx][95:64];
            end
            else begin
                Cache_RD = Cache[idx][127:96];
            end
        end
    end

    //Load miss
    always @(posedge CLK) begin
        if(XM_cur_type == LW_type & is_hit == 0) begin
            //Cache update
            if(temp_BO == 2'b00) begin
                Cache[idx][31:0] <= D_MEM_DI;
            end
            else if(temp_BO == 2'b01) begin
                Cache[idx][63:32] <= D_MEM_DI;
            end 
            else if(temp_BO == 2'b10) begin
                Cache[idx][95:64] <= D_MEM_DI;
            end
            else begin
                Cache[idx][127:96] <= D_MEM_DI;
                Cache[idx][133:129] <= tag;
                Cache[idx][128] <= 1;
            end
            temp_BO <= temp_BO + 1;
        end
    end

    always @(*) begin
        if(XM_cur_type == LW_type & is_hit == 0) begin
            //Cache update
            D_MEM_ADDR_REG = {temp_D_MEM_ADDR[11:4], temp_BO, temp_D_MEM_ADDR[1:0]};
        end
    end

    //Store hit
    always @(*) begin
        if(XM_cur_type == SW_type & is_hit) begin
            if(BO == 2'b00) begin
                Cache[idx][31:0] = XM_RD2;
            end
            else if(BO == 2'b01) begin
                Cache[idx][63:32] = XM_RD2;
            end
            else if(BO == 2'b10) begin
                Cache[idx][95:64] = XM_RD2;
            end
            else begin
                Cache[idx][127:96] = XM_RD2;
            end
            D_MEM_ADDR_REG = temp_D_MEM_ADDR;
        end
    end
    
    always @(*) begin
        if(XM_cur_type == SW_type & is_hit == 0) begin
            if(temp_BO == BO) begin
                XM_D_MEM_WEN = 0;
            end
            else begin
                XM_D_MEM_WEN = 1;
            end
            D_MEM_ADDR_REG = {temp_D_MEM_ADDR[11:4], temp_BO, temp_D_MEM_ADDR[1:0]};
        end
    end

    always @(posedge CLK) begin
        if(XM_cur_type == SW_type & is_hit == 0) begin
            //Cache update
            if(temp_BO == 2'b00 & temp_BO != BO) begin
                Cache[idx][31:0] <= D_MEM_DI;
            end
            else if(temp_BO == 2'b01 & temp_BO != BO) begin
                Cache[idx][63:32] <= D_MEM_DI;
            end 
            else if(temp_BO == 2'b10 & temp_BO != BO) begin
                Cache[idx][95:64] <= D_MEM_DI;
            end
            else if(temp_BO == 2'b11) begin
                if(temp_BO != BO) begin
                    Cache[idx][127:96] <= D_MEM_DI;
                end
                Cache[idx][133:129] <= tag;
                Cache[idx][128] <= 1;
            end
            temp_BO <= temp_BO + 1;
        end
    end



	////////////////////////////////////////////////////////////////
    ////////////////////     MEM stage     /////////////////////////
    ////////////////////////////////////////////////////////////////
    reg MB_is_hit;

    assign D_MEM_ADDR = D_MEM_ADDR_REG;
    assign D_MEM_DOUT = XM_RD2;

    assign D_MEM_WEN = XM_D_MEM_WEN;
    assign D_MEM_BE = XM_D_MEM_BE;

    always @(posedge CLK) begin
        if(RSTn) begin
            if(is_hit) begin
                //data path
                MB_D_MEM_RD <= Cache_RD;
                MB_ALU_result <= XM_ALU_result;
                MB_WA <= XM_WA;

                //control path
                MB_WDsrc <= XM_WDsrc;
                MB_RF_WE <= XM_RF_WE;
                MB_inst_register <= XM_inst_register;
            end
            MB_is_hit <= is_hit;
        end
    end

    reg [31:0] WB_inst_register;

    always @(posedge CLK) begin
        if(RSTn) begin
            if(is_hit) begin
                WB_inst_register <= MB_inst_register;
            end
        end
    end


    ////////////////////////////////////////////////////////////////
    ////////////////////      WB stage     /////////////////////////
    ////////////////////////////////////////////////////////////////
    
    assign RF_WA1 = MB_WA;
    assign RF_WD = (MB_WDsrc) ? MB_D_MEM_RD : MB_ALU_result;
    assign RF_WE = MB_RF_WE;

    assign OUTPUT_PORT = RF_WD;


    //check halt condition
	assign HALT = (terminate_flag) ? ((MB_inst_register == 32'h00008067)? 1 : 0) : 0;

	assign terminate_flag = (terminate_flag)? ((WB_inst_register == 32'h00c00093)? 1 : 0) : ((WB_inst_register == 32'h00c00093)? 1 : 0);

	// Only allow for NUM_INST
	always @(negedge CLK) begin
		if (RSTn & (MB_inst_register != 32'h00000013) & MB_is_hit) begin
            NUM_INST <= NUM_INST + 1;
        end
    end

    always @(*) begin
        //DX_RD1
        if(ID1_src == 3'b000) begin
            ID_RF_RD1 = ALU_result;
        end
        if(ID1_src == 3'b001) begin
            ID_RF_RD1 = Cache_RD;
        end
        if(ID1_src == 3'b010) begin
            ID_RF_RD1 = XM_ALU_result;
        end
        if(ID1_src == 3'b011) begin
            ID_RF_RD1 = RF_WD;
        end
        if(ID1_src == 3'b100) begin
            ID_RF_RD1 = RF_RD1;
        end
    end


endmodule 
