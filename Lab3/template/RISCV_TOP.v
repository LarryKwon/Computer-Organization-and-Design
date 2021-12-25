module RISCV_TOP (
	//General Signals
	input wire CLK,
	input wire RSTn,

	//I-Memory Signals
	output wire I_MEM_CSN, //if RSTn == 1 -> CSN  = 0 / if RSTn == 0 -> CSN = 1 
	input wire [31:0] I_MEM_DI,//input from IM, the instruction
	output reg [11:0] I_MEM_ADDR,//in byte address to access instruction

	//D-Memory Signals
	output wire D_MEM_CSN, // if RSTn == 1 -> CSN  = 0 / if RSTn == 0 -> CSN = 1
	input wire [31:0] D_MEM_DI,// output from data memeory. the data what we read
	output wire [31:0] D_MEM_DOUT, // the data that we write on addr
	output wire [11:0] D_MEM_ADDR,//in word address
	output wire D_MEM_WEN, // if we want to execute the instruction that store data to memory, we make WEN = 0
	output wire [3:0] D_MEM_BE, // // 바이트 단위를 조정하기 위해 사용, byte enable 값으로 data를 읽거나 할 때(SB, SH, SW, LB, LH, LW 를 할 때 필요)

	//RegFile Signals
	output wire RF_WE, //register에 값을 저장하려고 할 때, 값이 1이 되어야함
	output wire [4:0] RF_RA1, // source register 1의 number를 만들어야 함
	output wire [4:0] RF_RA2, // source register 2의 number를 만들어야 함
	output wire [4:0] RF_WA1, // write register 1의 number를 만들어야 함
	input wire [31:0] RF_RD1, // source register 1로 부터 읽을 값
	input wire [31:0] RF_RD2, // source register 2로 부터 읽을 값
	output wire [31:0] RF_WD, // register file에 넣을 data
	output wire HALT,                   // if set, terminate program
	output reg [31:0] NUM_INST,         // number of instruction completed
	output wire [31:0] OUTPUT_PORT      // equal RF_WD this port is used for test

	);

	//connect to regfile
	assign RF_RA1 = I_MEM_DI[19:15];
	assign RF_RA2 = I_MEM_DI[24:20];
	assign RF_WA1 = I_MEM_DI[11:7];

	//connect CSNs of I-Mem, D-Mem
	assign I_MEM_CSN = ~RSTn;
	assign D_MEM_CSN = ~RSTn;

	//ImmGen
	wire[31:0] imm;

	//control unit
	wire is_sign; // control_unit to alu_unit, branch_comp
	wire[2:0] imm_control; // control_unit to ImmGen
	wire ASel; // control_unit to alu_unit
	wire BSel; // control_unit to alu_unit
	wire[4:0] alu_control; // control_unit to alu_unit
	wire[1:0] wb_control; // for pcSel, from control_unit
	wire pcSel;

	//termination & output Port
	wire termination_flag = 0;
	reg termination_flag_reg;
	reg[6:0] opcode;
	reg HALT_reg;

	assign termination_flag = termination_flag_reg;
	assign HALT = HALT_reg;
	assign opcode = I_MEM_DI[6:0];

	//alu unit
	wire[31:0] alu_result;
	reg [11:0] pc;

	//BranchComp
	wire BrEq; // BranchComp to controlUnit
	wire BrLt; // BranchComp to controlUnit

	//port instantiation of ImmGen
	ImmGen imm_gen1(
		.RSTn			(RSTn),
		.imm_control	(imm_control),
		.I_MEM_DI		(I_MEM_DI),
		.imm			(imm)
	);

	//port instantiation of BranchComp
	BranchComp branch_comp(
		.RSTn 		(RSTn),
		.is_sign 	(is_sign),
		.RF_RD1  	(RF_RD1), // source register 1로 부터 읽을 값
		.RF_RD2  	(RF_RD2), // source register 2로 부터 읽을 값
   		.BrEq    	(BrEq),
    	.BrLt    	(BrLt)
	);

	//port instantiation of control_unit
	ControlUnit control_unit(
		.RSTn			(RSTn),
		.I_MEM_DI		(I_MEM_DI),
		.BrEq			(BrEq),		
		.BrLt			(BrLt),
		.imm_control	(imm_control),
		.RF_WE			(RF_WE),
		.D_MEM_WEN		(D_MEM_WEN),
		.D_MEM_BE		(D_MEM_BE),
		.is_sign		(is_sign),
		.ASel			(ASel),
		.BSel			(BSel),
		.alu_control	(alu_control),
		.wb_control		(wb_control),
		.pcSel			(pcSel)
	);

	AluUnit alu_unit(
		 .RSTn			(RSTn),
		 .ASel			(ASel),
		 .BSel			(BSel),
		 .is_sign		(is_sign),
		 .alu_control	(alu_control),
		 .RF_RD1		(RF_RD1), // source register 1로 부터 읽을 값
		 .RF_RD2		(RF_RD2), // source register 2로 부터 읽을 값
		 .imm			(imm),
		 .pc			(pc),
		 .alu_result	(alu_result)
	);

	/*
	if(opcode == 7'b1100011 ) begin
		assign OUTPUT_PORT = pcSel;	
	end
	else begin
		if(opcode == 7'b0100011 ) begin
			assign OUTPUT_PORT = alu_result;
		end
		else begin
			assign OUTPUT_PORT = RF_WD;
		end
	end
	*/

	assign OUTPUT_PORT = (opcode == 7'b1100011)? pcSel:
	(opcode == 7'b0100011)? alu_result : RF_WD;

	
	initial begin
		NUM_INST <= 0;
		pc <= 0;
	end

	// Only allow for NUM_INST
	always @ (negedge CLK) begin
		if (RSTn) NUM_INST <= NUM_INST + 1;
	end

	
	always @(RSTn) begin
		
		I_MEM_ADDR = pc;
		
	end

	// TODO: implement
	
	/*
	//write-back 컨트롤
	// alu_result가 저장
	if(wb_control == 2'b00) begin
		assign RF_WD = alu_result;
	end
	// D_mem_out 이 저장
	else if(wb_control == 2'b01) begin
		assign RF_WD = D_MEM_DI;
	end
	// pc + 4 가 저장
	else if(wb_control == 2'b10) begin
		assign RF_WD = pc+4;
	end
	// LUI일 때 Imm가 저장
	else if(wb_control == 2'b11) begin
		assign RF_WD = imm;
	end
	*/

	assign RF_WD = (wb_control == 2'b00)? alu_result :
	(wb_control == 2'b01)? D_MEM_DI :
	(wb_control == 2'b10)? pc+4 : imm;

	//Write Data를 선택
	assign D_MEM_DOUT = RF_RD2;
	//Mem Addr 연결
	assign D_MEM_ADDR = alu_result & 16'h3FFF;


	always@(*) begin
		I_MEM_ADDR = pc & 12'hFFF;

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

	always@(posedge CLK) begin
		// next pc
		// pc = alu result
		if(RSTn==1) begin
			if(pcSel == 1) begin
				pc = alu_result;
			end
			// pc = pc + 4;
			else begin
				pc = pc + 4;
			end
		end
		else begin
			pc = 0;
		end
	end

	// assign termination_flag = (I_MEM_DI == 32'h00c00093)? 1:
	// (termination_flag == 1) ? 1 : 0;

	/*
	if(I_MEM_DI == 32'h00c00093 ) begin
		assign termination_flag = 1;
	end
	else begin
		if(termination_flag == 1) begin
			assign termination_flag = 1;	
		end
		else begin
			assign termination_flag = 0;
		end
	end
	*/
	// assign HALT = (termination_flag & (I_MEM_DI == 32'h00008067 ))? 1: 0;

	/*
	if(termination_flag & (I_MEM_DI == 32'h00008067)) begin
		assign HALT = 1;
	end 
	else begin
		assign termination_flag = 0;
		assign HALT = 0;
	end
	*/
	
endmodule 
