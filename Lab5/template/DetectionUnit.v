module DetectionUnit(
    input wire RSTn	
    input wire memWrite
    input wire[4:0] RD_EX	
    input wire[4:0] RS1_ID	
    input wire[4:0] RS2_ID	
    input wire IF_ID_WE	
    input wire pcWrite	
    input wire isNop
);

ID/EX.MemRead and
ID/EX.RegisterRd !=0 and
((ID/EX.RegisterRd == IF/ID.RegisterRs1) or
(ID/EX.RegisterRd == IF/ID.RegisterRs2))

reg pcWrite_reg;
reg isNop_reg;
reg IF_ID_WE_reg;

assign pcWrite = pcWrite_reg;
assign isNop = isNop_reg;
assign IF_ID_WE = IF_ID_WE_reg;

always@(*) begin
    if(memWrite == 0 & RD_EX != 0) begin
        if(RS1_ID == RD_EX | RS2_ID == RD_EX) begin
            isNop_reg = 1'b1;
            pcWrite_reg = 1'b0;
            IF_ID_WE_reg = 1'b0;
        end
        else begin
            isNop_reg = 1'b0;
            pcWrite_reg = 1'b1;
            IF_ID_WE_reg = 1'b1;
        end
    end
    else begin
        isNop_reg = 1'b0;
        pcWrite_reg = 1'b1;
        IF_ID_WE_reg = 1'b1;
    end
end