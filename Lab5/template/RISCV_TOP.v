module RISCV_TOP (
	//General Signals
	input wire CLK,
	input wire RSTn,

	//I-Memory Signals
	output wire I_MEM_CSN,
	input wire [31:0] I_MEM_DI,//input from IM
	output reg [11:0] I_MEM_ADDR,//in byte address

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
	output wire [31:0] OUTPUT_PORT      // equal RF_WD this port is used for test
	);

    /* wire 및 reg 선언부 */
    //register 및 wire
    
    //IF
    reg [11:0] pc; 
    reg [31:0] INST_IF_ID;   
    reg [11:0] pc_IF_ID;

    //ID
    reg [31:0] RF_RD1_ID_EX; //RD1값 저장 reg
	reg [31:0] RF_RD2_ID_EX; //RD2값 저장 reg
    reg [11:0] pc_ID_EX;
    reg [31:0] INST_ID_EX;
    wire[4:0]  RA1_EX;
    wire[4:0] RA2_EX;

    //ex
    wire[31:0] imm;
    reg [31:0] alu_out;
    reg [31:0] RF_RD2_EX_MEM;
    reg [11:0] pc_EX_MEM;
    reg [31:0] INST_EX_MEM;
    wire[4:0] WA_MEM;
    //alu unit
	wire[31:0] alu_result;
    reg [31:0] alu_out;
    //BranchComp
	wire BrEq; // BranchComp to controlUnit
	wire BrLt; // BranchComp to controlUnit

    //MEM

    //WB
    reg [31:0] RF_WD_MEM_WB;
    reg [31:0] INST_MEM_WB;
    wire[4:0] WA_WB;

    // control signals
    /*EX*/
    wire [4:0] alu_control;
    wire is_sign;
    wire [2:0] imm_control;
    wire ASel;
    wire BSel;
    /*MEM*/
    wire memWrite;
    wire [3:0] memByte;
    /*WB*/
    wire [1:0] wbSel;
    wire regWrite;

    /*for stall*/    
    wire isNop_IF_ID;
    wire isNop_ID_EX;
    wire IF_ID_WE;
    wire pcWrite;

    //forwardUnit
    wire [1:0] forwardA;
    wire [1:0] forwardB;
    
    /*BTB <-> control unit*/
    wire misPredict; // BTB to controlUnit
    wire pred; // BTB to PC
    wire isTaken; // controlUnit to BTB
    wire target_addr; // BTB to PC

	//output port -> 수정 필요
	assign OUTPUT_PORT = (opcode == 7'b1100011)? ~misPredict:
	(opcode == 7'b0100011)? alu_out : RF_WD;

    /*초기화 */
	initial begin
		NUM_INST <= 0;
        pc <= 0;
	end
    
    assign I_MEM_CSN = ~RSTn;
    assign D_MEM_CSN = ~RSTn;
    always @(RSTn) begin
		I_MEM_ADDR = pc;
		INST_IF_ID = I_MEM_DI;
	end

	// Only allow for NUM_INST
	always @ (negedge CLK) begin
		if (RSTn) NUM_INST <= NUM_INST + 1;
	end

    /*포트 연결부*/
    BranchComp branch_comp(
		.RSTn 		(RSTn),
		.is_sign 	(is_sign),
		.RF_RD1  	(RF_RD1_ID_EX), // source register 1로 부터 읽을 값
		.RF_RD2  	(RF_RD2_ID_EX), // source register 2로 부터 읽을 값
   		.BrEq    	(BrEq),
    	.BrLt    	(BrLt)
	);

    ImmGen imm_gen1(
		.RSTn				(RSTn),
		.imm_control	    (imm_control),
		.I_MEM_DI			(INST_ID_EX),
		.imm				(imm)
	);

    AluUnit alu_unit(
        .RSTn			(RSTn),
        .ASel           (ASel),
        .BSel           (BSel),
        .forwardA		(forwardA),
        .forwardB		(forwardB),
        .is_sign		(is_sign),
        .alu_control	(alu_control),
        .RF_RD1			(RF_RD1_ID_EX), // source register 1로 부터 읽을 값
        .RF_RD2			(RF_RD2_ID_EX), // source register 2로 부터 읽을 값
        .imm			(imm),
        .pc				(pc_ID_EX),
        .alu_result	    (alu_result),
        .br_control	    (br_control)
	);

	ControlUnit control_unit(
		.RSTn			(RSTn),
		.INST_IF_ID		(INST_IF_ID),
        .INST_ID_EX     (INST_ID_EX),
		.BrEq			(BrEq),		
		.BrLt			(BrLt),
		.imm_control	(imm_control),
		.regWrite		(regWrite),
		.memWrite		(memWrite),
		.memByte		(memByte),
		.is_sign		(is_sign),
		.ASel			(ASel),
		.BSel			(BSel),
		.alu_control	(alu_control),
		.wbSel		    (wbSel),
        .misPredict     (misPredict),
        .isTaken        (isTaken),
        .pcWrite        (pcWrite),
        .IF_ID_WE       (IF_ID_WE),
        .isNop_IF_ID    (isNop_IF_ID),
        .isNop_ID_EX    (isNop_ID_EX)
	);

    /* datapath 연결부 */

    /*IF datapath*/
    always @(*) begin
        I_MEM_ADDR = pc & 12'hFFF;
    end
    /*
        pc +4  and BTB logic 추가
    */

    // IF/ID register
    //instruction reg
    always @(posedge CLK) begin
        INST_IF_ID = I_MEM_DI;
    end
    //pc
    always @(posedge CLK) begin
        pc_IF_ID = pc;
    end
    

    /*ID datapath*/
    //connect to RA1, RA2 of RegisterFile
	assign RF_RA1 = INST_IF_ID[19:15];
	assign RF_RA2 = INST_IF_ID[24:20];
	
    // ID/EX register
    // RF_RD1, RF_RD2
	always @(*) begin
		RF_RD1_ID_EX = RF_RD1;
		RF_RD2_ID_EX = RF_RD2;
	end
    //pc_IFID
    always @(posedge CLK) begin
        pc_ID_EX = pc_IF_ID;
    end
    //instruction reg
    always @(*) begin
        INST_ID_EX = INST_IF_ID
    end

    /*EX datapath*/
    //connect to branchComp

    

    
    //termination & output Port
	wire termination_flag = 0;
	reg termination_flag_reg;
	reg[6:0] opcode;
	reg HALT_reg;

	assign termination_flag = termination_flag_reg;
	assign HALT = HALT_reg;
	assign opcode = INST_IFID[6:0];

	always@(*) begin
		// 종료 조건 설정
		if(I_MEM_DI_reg == 32'h00c00093 ) begin
			termination_flag_reg = 1;
		end
		else begin
			if(I_MEM_DI_reg == 32'h00008067 && termination_flag_reg == 1) begin
				termination_flag_reg = 1;
			end
			else begin
				termination_flag_reg = 0;
			end
		end

		if(termination_flag_reg & (I_MEM_DI_reg == 32'h00008067)) begin
			HALT_reg = 1;
		end 
		else begin
			HALT_reg = 0;
		end
	end
endmodule //
