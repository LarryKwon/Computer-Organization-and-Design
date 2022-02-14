module BTB(
    input wire RSTn,
    input wire CLK,
    input wire[31:0] INST_ID_EX,
    input wire[11:0] pc_ID_EX,
    input wire[11:0] pc,
    input wire isTaken,
    input wire[31:0] updatedAddr,
    output wire[11:0] nextPc,
    output wire misPredict
);

    /* 내부 처리 레지스터들 */
    reg[11:0] nextPc_reg;
    reg misPredict_reg;
    reg[11:0] realAddr;
    reg[11:0] predAddr;
    reg predTaken;
    reg predTaken_EX;
    
    reg[6:0] opcode;

    assign nextPc = nextPc_reg;
    assign misPredict = misPredict_reg;
    
    

    //실제 table
    reg [13:0] btb [4095:0];
    reg [14:0]i;
    initial begin
        for(i=0; i<4096; i=i+1) begin
           btb[i] = i + 4; 
        end
    end

    //define synchronous write 
    always @(posedge CLK) begin
        //2-bit saturation update
        if(RSTn == 1) begin
            if(opcode == 7'b1100011 | opcode == 7'b1101111 | opcode == 7'b1100111) begin   
                if(isTaken != predTaken_EX) begin
                    if(isTaken == 1) begin
                        btb[pc_ID_EX][13:12] <= btb[pc_ID_EX][13:12] +1 ;
                    end
                    else begin
                        btb[pc_ID_EX][13:12] <= btb[pc_ID_EX][13:12] -1 ;
                    end
                end
                else begin
                    if(isTaken == 1) begin
                        if(btb[pc_ID_EX][13:12] == 2'b10) begin
                            btb[pc_ID_EX][13:12] <= btb[pc_ID_EX][13:12] +1;
                        end 
                    end
                    else begin
                        if(btb[pc_ID_EX][13:12] == 2'b01) begin
                            btb[pc_ID_EX][13:12] <= btb[pc_ID_EX][13:12] -1;
                        end 
                    end
                end
            end
        end
    end

    always @(negedge CLK ) begin
        if(RSTn == 1) begin
            //btb update의 target update
            if(opcode == 7'b1100011 | opcode == 7'b1101111 | opcode == 7'b1100111) begin
                btb[pc_ID_EX][11:0] <= updatedAddr[11:0];
                //$display("updatedAddr %d", btb[pc_ID_EX][11:0]);
            end
        end
    end

    //define asynchronous read
    always @(*) begin
        if(RSTn == 1) begin
            opcode = INST_ID_EX[6:0];

            //predTaken, 0인지 1인지 // comb
            if(btb[pc][13:12] == 2'b11 | btb[pc][13:12] == 2'b10) begin
                predTaken = 1;
            end
            else begin
                predTaken = 0;
            end
            //comb
            if(btb[pc_ID_EX][13:12] == 2'b11 | btb[pc_ID_EX][13:12] == 2'b10) begin
                predTaken_EX = 1;
            end
            else begin
                predTaken_EX = 0;
            end     

            //predTaken에 따른 predAddr값 결정
            if(predTaken) begin
                predAddr = btb[pc][11:0];
                // $display("predAddr in btb %d", btb[pc][11:0]);
            end
            else begin
                predAddr = pc + 4;
                //$display("predAddr is not in btb, so pc+4 %d", btb[pc][11:0]);
            end

            //isTaken과 predTaken에 따른 misPredict 값 결정
            if(opcode == 7'b1100011 | opcode == 7'b1101111 | opcode == 7'b1100111) begin   
                if(isTaken != predTaken_EX) begin
                    misPredict_reg = 1;
                end
                else begin
                    misPredict_reg = 0;
                end 
            end
            else begin
                misPredict_reg = 0;
            end

            //misPredict 값에 따른 realAddr 값 결정
            if(misPredict_reg) begin
                if(isTaken == 1) begin
                    realAddr = btb[pc_ID_EX][11:0];
                end
                else begin
                    realAddr = pc_ID_EX +4;
                end
            end

            //misPredict 값에 따른 nextPc 값 결정
            if(misPredict_reg) begin
                nextPc_reg = realAddr;
            end
            else begin
                nextPc_reg = predAddr;
            end
        end
    end

endmodule
