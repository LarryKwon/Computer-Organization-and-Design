module ForwardUnit(
    input wire RSTn,
    input wire CLK,
    input wire[4:0] RS1_EX,	
    input wire[4:0] RS2_EX,        
    input wire[4:0] RD_MEM,   
    input wire[4:0] RD_WB,       
    input wire regWrite_MEM,
    input wire regWrite_WB,
    input wire ID_EX_WE,  
    output wire[1:0] forwardA,
    output wire[1:0] forwardB
);

    reg[1:0] forwardA_reg;
    reg[1:0] forwardB_reg;
    reg ID_EX_WE_reg;

    assign forwardA = forwardA_reg;
    assign forwardB = forwardB_reg;

    always @(posedge CLK) begin
        ID_EX_WE_reg <= ID_EX_WE;
    end

    always @(*) begin
        if(RSTn == 1) begin
            //forwardA값 설정
            if(ID_EX_WE_reg) begin
                if(regWrite_MEM == 1 & RD_MEM != 0 & RD_MEM == RS1_EX) begin
                    forwardA_reg = 2'b10;         
                end
                else if(regWrite_WB == 1 & RD_WB != 0 & ~(regWrite_MEM ==1 & RD_MEM != 0 & RD_MEM == RS1_EX) & RD_WB == RS1_EX) begin
                    forwardA_reg = 2'b01;
                end
                else begin
                    forwardA_reg = 2'b00;
                end
                //forwardB값 설정
                if(regWrite_MEM == 1 & RD_MEM != 0 & RD_MEM == RS2_EX) begin
                    forwardB_reg = 2'b10;         
                end
                else if(regWrite_WB == 1 & RD_WB != 0 & ~(regWrite_MEM == 1 & RD_MEM != 0 & RD_MEM == RS2_EX) & RD_WB == RS2_EX) begin
                    forwardB_reg = 2'b01;
                end
                else begin
                    forwardB_reg = 2'b00;
                end
            end



            /*
            if(regWrite_MEM == 1 & RD_MEM != 0) begin
                if(RD_MEM == RS1_EX) begin
                    forwardA_reg = 2'b10;
                    forwardB_reg = 2'b00;
                end
                else if(RD_MEM == RS2_EX) begin
                    forwardB_reg = 2'b10;
                    forwardA_reg = 2'b00;
                end
                else begin
                    forwardB_reg = 2'b00;
                    forwardA_reg = 2'b00;
                end
            end
            else if(regWrite_WB == 1 & RD_WB != 0)begin
                if(RD_WB == RS1_EX) begin
                    forwardA_reg = 2'b01;
                    forwardB_reg = 2'b00;
                end
                else if(RD_WB == RS2_EX) begin
                    forwardB_reg = 2'b01;
                    forwardA_reg = 2'b00;
                end
                else begin
                    forwardB_reg = 2'b00;
                    forwardA_reg = 2'b00;
                end
            end
            else begin
                forwardA_reg = 2'b00;
                forwardB_reg = 2'b00;
            end
            */
        end
    end
    
endmodule