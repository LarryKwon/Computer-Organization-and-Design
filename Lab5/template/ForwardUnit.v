module ForwardUnit(
    input wire RSTn           
    input wire[4:0] RS1_EX	
    input wire[4:0] RS2_EX         
    input wire[4:0] RD_MEM   
    input wire[4:0] RD_WB       
    input wire regWrite_MEM
    input wire regWrite_WB    
    output wire[1:0] forwardA
    output wire[1:0] forwardB
);

reg[1:0] forwardA_reg;
reg[1:0] forwardB_reg;

assign forwardA = forwardA_reg;
assign forwardB = forwardB_reg;

always @(*) begin
    if(RSTn == 1) begin
        if(regWrite_MEM == 1 & RD_MEM != 0) begin
            if(RD_MEM == RS1_EX) begin
                forwardA_reg = 2'b10;
            end
            else if(RD_MEM == RS2_EX) begin
                forwardB_reg = 2'b10;
            end
        end
        else if(regWrite_WB == 1 & RD_WB != 0)begin
            if(RD_WB == RS1_EX) begin
                forwardA_reg = 2'b01;
            end
            else if(RD_WB == RS2_EX) begin
                forwardB_reg = 2'b01;
            end
        end
        else begin
            forwardA_reg = 2'b00;
            forwardB_reg = 2'b00;
        end
    end
end