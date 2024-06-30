module PCLoadBox (
    input wire PCWrite,
    input wire PCCond,
    input wire BranchOption,
    output wire PCLoad
);
    assign PCLoad = PCWrite | (PCCond & BranchOption);
endmodule