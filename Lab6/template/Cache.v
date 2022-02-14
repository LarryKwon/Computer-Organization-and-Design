module Cache(
    input wire RSTn,
    input wire CLK,
    input wire[31:0] INST_EX_MEM,
    input wire[31:0] ADDR,
    output wire hit,
    output wire IF_ID_WE,
    output wire ID_EX_WE,
    output wire EX_MEM_WE,
    output wire pc_ID_EX_WE,
    output wire pc_EX_MEM_WE,
    output wire isNop_MEM_WB
);

