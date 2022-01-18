module RISCV_TOP (
	//General Signals
	input wire CLK,
	input wire RSTn,

	//I-Memory Signals
	output wire I_MEM_CSN, // RSTn == 1 -> CSN = 0, RSTn == 0 -> CSN = 1
	input wire [31:0] I_MEM_DI,//input from IM
	output reg [11:0] I_MEM_ADDR,//in byte address

	//D-Memory Signals
	output wire D_MEM_CSN, // RSTn == 1 -> CSN = 0, RSTn == 0 -> CSN = 1
	input wire [31:0] D_MEM_DI, // read data 
	output wire [31:0] D_MEM_DOUT, // write data
	output wire [11:0] D_MEM_ADDR,//in word address
	output wire D_MEM_WEN, // write시 WEN = 0
	output wire [3:0] D_MEM_BE, // byte enable 값

	//RegFile Signals
	output wire RF_WE, // register에 값을 쓸 때 1, 아니면 0
	output wire [4:0] RF_RA1, // register1의 넘버
	output wire [4:0] RF_RA2, // register2의 넘버
	output wire [4:0] RF_WA1, // write regiserdml 넘버
	input wire [31:0] RF_RD1, //  RA1로부터의 값
	input wire [31:0] RF_RD2, // RA2로부터의 값
	output wire [31:0] RF_WD, // register에 쓸 값
	output wire HALT, // terminate
	output reg [31:0] NUM_INST, // 몇 번째 inst인지, 끝날 때 1씩 올려야한다.
	output wire [31:0] OUTPUT_PORT // 
	);

	// TODO: implement multi-cycle CPU

	//connect to I_MEM
	// IR_WRITE 필요 -> control_unit
	assign I_MEM_CSN = ~RSTn;
	reg[31:0] I_MEM_DI_reg;
	wire IR_WE;
	

	always @(posedge CLK) begin
		if(IR_WE == 1) begin
			I_MEM_DI_reg = I_MEM_DI;
		end
	end

	//connect to regfile
	assign RF_RA1 = I_MEM_DI_reg[19:15];
	assign RF_RA2 = I_MEM_DI_reg[24:20];
	assign RF_WA1 = I_MEM_DI_reg[11:7];
	
	reg[31:0] RF_RD1_reg; //RD1값 저장 reg
	reg[31:0] RF_RD2_reg; //RD2값 저장 reg
	always @(*) begin
		RF_RD1_reg = RF_RD1;
		RF_RD2_reg = RF_RD2;
	end

	//ImmGen
	wire[31:0] imm;

	//alu unit
	wire[31:0] alu_result;
	reg[31:0] alu_out;
	wire ALU_REG_WE;
	always @(posedge CLK) begin
		if(ALU_REG_WE == 1) begin
			alu_out = alu_result;	
		end
	end
	

	//BranchComp
	wire[1:0] br_control; // BranchComp in alu_unit to controlUnit

	//connect to D_MEM
	assign D_MEM_CSN = ~RSTn;
	assign D_MEM_DOUT = RF_RD2_reg; //Write Data 연결
	assign D_MEM_ADDR = alu_out & 16'h3FFF; //Mem Addr 연결


	//pc & stage
	//pcWrite 필요 -> control_unit
	reg [11:0] pc;
	reg [11:0] old_pc;
	wire [2:0] stage;
	wire PC_WE; // sequential logic 에 사용

	always @(posedge CLK) begin // old_pc에 pc값을 연결
		if(IR_WE == 1) begin
			old_pc = pc;
		end
	end

	//termination & output Port
	wire termination_flag = 0;
	reg termination_flag_reg;
	reg[6:0] opcode;
	reg HALT_reg;

	assign termination_flag = termination_flag_reg;
	assign HALT = HALT_reg;
	assign opcode = I_MEM_DI[6:0];

	//control unit
    wire [2:0] imm_control; // immediate 생성 관련
    wire is_sign; // sign 명령어인지 아닌지
    wire [1:0] ASel; // RF_RD1, pc, oldPc
    wire [1:0] BSel; // RF_RD2, imm, 4
    wire [4:0] alu_control; //alu control decoder
    wire [1:0] wbSel;   //wbSel
												// - 00: Alu_out
												// - 01: D_MEM_OUT
												// - 10: AluResult
												// - 11: Imm
    wire pcSel;   // pcSel
									// - 0: alu_result(즉시 계산값)
									// - 1: alu_out(저장값)



	//port instantiation of ImmGen
	ImmGen imm_gen1(
		.RSTn					(RSTn),
		.imm_control	(imm_control),
		.I_MEM_DI			(I_MEM_DI_reg),
		.imm					(imm)
	);

	AluUnit alu_unit(
		 .RSTn				(RSTn),
		 .ASel				(ASel),
		 .BSel				(BSel),
		 .is_sign			(is_sign),
		 .alu_control	(alu_control),
		 .RF_RD1			(RF_RD1_reg), // source register 1로 부터 읽을 값
		 .RF_RD2			(RF_RD2_reg), // source register 2로 부터 읽을 값
		 .imm					(imm),
		 .pc					(pc),
		 .old_pc			(old_pc),
		 .alu_result	(alu_result),
		 .br_control	(br_control)
	);

	ControlUnit control_unit(
		.RSTn					(RSTn),
		.CLK				(CLK),
		.I_MEM_DI			(I_MEM_DI_reg),
		.br_control		(br_control),
		.imm_control	(imm_control),
		.RF_WE				(RF_WE),
		.D_MEM_WEN		(D_MEM_WEN),
		.D_MEM_BE			(D_MEM_BE),
		.is_sign			(is_sign),
		.ASel					(ASel),
		.BSel					(BSel),
		.alu_control	(alu_control),
		.wbSel				(wbSel),
		.ALU_REG_WE		(ALU_REG_WE),
		.IR_WE				(IR_WE),
		.PC_WE				(PC_WE),
		.pcSel				(pcSel),
		.stage				(stage)
	);

	//초기화
	initial begin
		NUM_INST <= 0;
		pc <= 0;
	end

	always @(RSTn) begin
		
		I_MEM_ADDR = pc;
		I_MEM_DI_reg  = I_MEM_DI;
	end

	//regWrite mux
	assign RF_WD = (wbSel == 2'b00)? alu_out :
	(wbSel == 2'b01)? D_MEM_DI :
	(wbSel == 2'b10)? alu_result : imm;


	//output port
	assign OUTPUT_PORT = (opcode == 7'b1100011)? pcSel:
	(opcode == 7'b0100011)? alu_out : RF_WD;

	//I_MEM_ADDR 설정
	always@(*) begin
		I_MEM_ADDR = pc & 12'hFFF;
		
		// 종료 조건 설정
		if(I_MEM_DI == 32'h00c00093 ) begin
			termination_flag_reg = 1;
		end
		else begin
			if(I_MEM_DI == 32'h00008067 && termination_flag_reg == 1) begin
				termination_flag_reg = 1;
			end
			else begin
				termination_flag_reg = 0;
			end
		end

		if(termination_flag_reg & (I_MEM_DI == 32'h00008067)) begin
			HALT_reg = 1;
		end 
		else begin
			HALT_reg = 0;
		end
	end

	always @(posedge CLK) begin
		// pc <= next_pc 값이 언제, 어떻게 일어나는지
		if(RSTn==1) begin
			if(PC_WE == 1) begin
				if(pcSel == 1) begin
					pc <= alu_out;
				end
				// pc = pc + 4;
				else begin
					pc <= alu_result;
				end
			end
		end
		else begin
				pc <= 0;
		end

	end

	// Only allow for NUM_INST
	always @ (negedge CLK) begin
		//Num_Inst 계산 어떻게 할지
		if (RSTn) begin
			if(opcode == 7'b1100011) begin
				if(stage == 3'b010) begin
					NUM_INST <= NUM_INST + 1;
				end
			end
			else if(opcode == 7'b0100011) begin
				if(stage == 3'b011) begin
					NUM_INST <= NUM_INST + 1;
				end
			end
			else begin
				if(stage == 3'b100) begin
					NUM_INST <= NUM_INST + 1;
				end
			end
		end
	end

	
endmodule //
