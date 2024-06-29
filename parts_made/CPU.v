
//incluindo vhd's dados pelo professor
// `include "../parts_given/Registrador.vhd"
// `include "../parts_given/RegDesloc.vhd"
// `include "../parts_given/ula32.vhd"
// `include "../parts_given/Memoria.vhd"
// `include "../parts_given/Instr_Reg.vhd"
// `include "../parts_given/Banco_reg.vhd"

//incluindo MUX's feitos pelo grupo
`include "../parts_made/mux/mux_ALU_A.v"
`include "../parts_made/mux/mux_ALU_B.v"
`include "../parts_made/mux/mux_ALUOut.v"
`include "../parts_made/mux/mux_divSrcA.v"
`include "../parts_made/mux/mux_hi&lo.v"
`include "../parts_made/mux/mux_MemAddr.v"
`include "../parts_made/mux/mux_MemWD.v"
`include "../parts_made/mux/mux_OptBranch.v"
`include "../parts_made/mux/mux_OptFlag.v"
`include "../parts_made/mux/mux_PC.v"
`include "../parts_made/mux/mux_RegDest.v"
`include "../parts_made/mux/mux_RegSrc.v"
`include "../parts_made/mux/mux_ShiftN.v"
`include "../parts_made/mux/mux_ShiftSrc.v"

//incluindo os componentes feitos pelo grupo
`include "../parts_made/concat.v"
`include "../parts_made/control_unit.v"
`include "../parts_made/div.v"
`include "../parts_made/mult.v"
`include "../parts_made/shiftLeft.v"
`include "../parts_made/signExtend.v"
`include "../parts_made/sizeLoad.v"
`include "../parts_made/sizeStore.v"
`include "../parts_made/srl.v"
`include "../parts_made/PCLoadBox.v"


module CPU (
    input wire clk,
    input wire reset
);

    //Control Wires Mux
    wire            mux_MemWD_selector;
    wire[2:0]       mux_MemAddr_selector;  
    wire            mux_high_low_selector;
    wire            mux_ShiftSrc_selector;
    wire            mux_ShiftN_selector;
    wire[1:0]       mux_ALU_A_selector; 
    wire[2:0]       mux_ALU_B_selector;
    wire[1:0]       mux_ALU_Out_selector;  
    wire[1:0]       mux_PC_selector;
    wire[1:0]       mux_WR_Registers_selector;
    wire[2:0]       mux_WD_Registers_selector;
    wire            mux_divSrcA_selector;

    //Control Wires Single Register 
    wire            EPC_Load;
    wire            PC_Load;
    wire            MDR_Load;
    wire            IR_Load;
    wire            HL_Load;
    wire            A_Load;
    wire            B_Load;
    wire            ALUOut_Load;

    //Control ULA Useless
    wire            NEGATIVE;
    wire            EQUAL;
    wire            LESS;

    //Control Wires Flags
    wire[1:0]       Store_Size_selector;
    wire[1:0]       Load_Size_selector;
    wire            Flag_selector;
    wire            Branch_selector;
    wire[2:0]       ALU_selector;
    wire[2:0]       Shift_selector;
    wire            Memory_WR;
    wire            Reg_WR;
    wire            PCWrite;
    wire            PCWriteCond;
    wire            GT;
    wire            ZERO;
    wire            OVERFLOW;

    //Control Wires (Mult)
    wire            MultInit;

    //Control Wires (Div)
    wire            DivInit;
    wire            DivZero;
    wire            DivOp;

    //Data Wires (Registradores)
    wire [31:0]     PC_Out;
    wire [31:0]     EPC_Out;
    wire [31:0]     MDR_Out;
    wire [31:0]     IR_Out;
    wire [31:0]     High_Out;
    wire [31:0]     Low_Out;
    wire [31:0]     A_Out;
    wire [31:0]     B_Out;
    wire [31:0]     ALUOut_Out;
    wire [31:0]     srl24_Out; 

    //Data Wires (Mux)
    wire [31:0]     mux_PC_Out;
    wire [31:0]     mux_Address_Out;  
    wire [31:0]     mux_WD_Memory_Out;
    wire [4:0]      mux_WR_Registers_Out;
    wire [31:0]     mux_WD_Registers_Out;
    wire [31:0]     mux_High_Out;
    wire [31:0]     mux_Low_Out;
    wire [31:0]     mux_divA_Out;
    wire [31:0]     mux_ShiftSrc_Out;
    wire [4:0]      mux_ShiftN_Out;
    wire [31:0]     mux_ALU1_Out; 
    wire [31:0]     mux_ALU2_Out;  
    wire [31:0]     mux_ALUOut_Out;  
    wire            mux_OptFlag_Out;
    wire            mux_OptBranch_Out;  

    //Data Wires (Outros)
    wire [31:0]     Store_Size_Out;
    wire [31:0]     Memory_Out;
    wire [5:0]      OPCODE;
    wire [4:0]      RS;
    wire [4:0]      RT;
    wire [15:0]     IMMEDIATE;
    wire [31:0]     Load_Size_Out;
    wire [31:0]     The_Box_Out;
    wire [25:0]     The_Box2_Out;
    wire [31:0]     RegDesloc_Out;
    wire [31:0]     Sign_Extend1_32_Out;
    wire [31:0]     Read_Data1_Out;
    wire [31:0]     Read_Data2_Out;
    wire [31:0]     Mult_High_Out;
    wire [31:0]     Div_High_Out;
    wire [31:0]     Mult_Low_Out;
    wire [31:0]     Div_Low_Out;
    wire [31:0]     Sign_Extend16_32_Out;
    wire [31:0]     Shift_Left32_32_Out;
    wire [27:0]     Shift_Left26_28_Out;
    wire [31:0]     ALU_Result;
    wire [31:0]     Shift_Left16_32_Out;

    mux_opt_flag mux_OptFlag_(
        Flag_selector,
        GT,
        ZERO,
        mux_OptFlag_Out
    );

    mux_opt_branch mux_OptBranch_(
        Branch_selector,
        mux_OptFlag_Out,
        mux_OptBranch_Out
    );

    PCLoadBox PC_LoadBox_(
        PCWrite,
        PCWriteCond,
        mux_OptBranch_Out,
        PC_Load
    );

    Registrador PC_(
        clk,
        reset,
        PC_Load, // PC_Load
        mux_PC_Out,
        PC_Out
    );

    memAddr mux_address_(
        mux_MemAddr_selector,
        PC_Out,
        ALUOut_Out,
        A_Out,
        B_Out,
        mux_Address_Out
    );

    mux_Mem_WD mux_wd_MEM_(
        mux_MemWD_selector,
        Store_Size_Out,
        ALUOut_Out,
        mux_WD_Memory_Out
    );
 
    SizeStore store_size_(
        MDR_Out,
        B_Out,
        Store_Size_selector,
        Store_Size_Out
    );

    Memoria MEM_(
        mux_Address_Out,
        clk,
        Memory_WR,
        mux_WD_Memory_Out,
        Memory_Out
    );

    Registrador mdr_(
        clk,
        reset,
        MDR_Load,
        Memory_Out,
        MDR_Out
    );

    Registrador EPC_(
        clk,
        reset,
        EPC_Load,
        ALU_Result,
        EPC_Out
    );

    Instr_Reg IR_(
        clk,
        reset,
        IR_Load,
        Memory_Out,
        OPCODE,
        RS,
        RT,
        IMMEDIATE
    );

    SizeLoad load_size_(
        MDR_Out,
        Load_Size_selector,
        Load_Size_Out
    );

    Concat_OFFSET the_box2_(
       IMMEDIATE,
       RT,
       RS,
       The_Box2_Out
    );

    mux_RegDest mux_wr_reg_(
       mux_WR_Registers_selector,
       RT,
       IMMEDIATE,
       mux_WR_Registers_Out
    );

    mux_RegSrc mux_wd_reg_(
       mux_WD_Registers_selector,
       Sign_Extend1_32_Out,
       RegDesloc_Out,
       Shift_Left16_32_Out,
       Load_Size_Out,
       ALUOut_Out,
       Low_Out,
       High_Out,
       mux_WD_Registers_Out
    );

    Registrador high_(
        clk,
        reset,
        HL_Load,
        mux_High_Out,
        High_Out
    );

    Registrador low_(
        clk,
        reset,
        HL_Load,
        mux_Low_Out,
        Low_Out
    );

    Banco_reg registers_(

        clk,
        reset,
        Reg_WR,
        RS,
        RT,
        mux_WR_Registers_Out,
        mux_WD_Registers_Out,
        Read_Data1_Out,
        Read_Data2_Out

    );

    mux_hi_lo mux_high_(
        mux_high_low_selector,
        Div_High_Out,
        Mult_High_Out,
        mux_High_Out
    );

    mux_hi_lo mux_low_(
        mux_high_low_selector,
        Div_Low_Out,
        Mult_Low_Out,
        mux_Low_Out
    );

    ShiftLeft_16to32 shift_left_16_32_(
        IMMEDIATE,
        Shift_Left16_32_Out
    );

    RegDesloc reg_desloc_(
        clk,
        reset,
        Shift_selector,
        mux_ShiftN_Out,
        mux_ShiftSrc_Out,
        RegDesloc_Out
    );

    mult mult_(
        A_Out,
        B_Out,
        clk,
        reset,
        MultInit,
        Mult_High_Out,
        Mult_Low_Out
    );

    mux_divSrcA mux_divSrcA_(
        DivOp,
        MDR_Out,
        A_Out,
        mux_divA_Out
    );

    div div_(
        mux_divA_Out,
        B_Out,
        clk,
        reset,
        DivInit,
        DivZero,
        Div_High_Out,
        Div_Low_Out
    );

    SignExtend sign_extend_(
        IMMEDIATE,
        Sign_Extend16_32_Out
    );

    Registrador A_(
        clk,
        reset,
        A_Load,
        Read_Data1_Out,
        A_Out
    );

     Registrador B_(
        clk,
        reset,
        B_Load,
        Read_Data2_Out,
        B_Out
    );

    mux_Shift_Src mux_entrada_(
        mux_ShiftSrc_selector,
        A_Out,
        B_Out,
        mux_ShiftSrc_Out
    );

    mux_Shift_n mux_n_(
        mux_ShiftN_selector,
        B_Out,
        IMMEDIATE,
        mux_ShiftN_Out
    );

    ShiftLeft_32to32 shift_left32_32_(
        Sign_Extend16_32_Out,
        Shift_Left32_32_Out
    );

    ShiftLeft_26to28 shift_left26_28_(
        The_Box2_Out,
        Shift_Left26_28_Out
    );

    ShiftRightLogical_24times srl24(
        Memory_Out,
        srl24_Out
    );

    mux_ALU_A mux_ALU1_(
        mux_ALU_A_selector,
        PC_Out,
        A_Out,
        srl24_Out,
        mux_ALU1_Out
    );

    mux_ALU_B mux_ALU2_(
        mux_ALU_B_selector,
        B_Out,
        Sign_Extend16_32_Out,
        Shift_Left32_32_Out,
        mux_ALU2_Out
    );

    Concat_JumpPC the_box_(
        Shift_Left26_28_Out,
        PC_Out,
        The_Box_Out
    );

    ula32 ALU_(

        mux_ALU1_Out,
        mux_ALU2_Out,
        ALU_selector,
        ALU_Result,
        OVERFLOW,
        NEGATIVE,
        ZERO,
        EQUAL,
        GT,
        LESS
    );

    ShiftRightLogical_1to32 sign_extend1_32_(
        LESS,
        Sign_Extend1_32_Out
    );

    mux_ALUOUT mux_ALUOut_(
        mux_ALU_Out_selector,
        Memory_Out,
        ALU_Result,
        mux_ALUOut_Out 
    );

    Registrador ALUOut_(
        clk,
        reset,
        ALUOut_Load,
        mux_ALUOut_Out, 
        ALUOut_Out
    );

    mux_PC mux_PC_(
        mux_PC_selector,
        ALU_Result,
        The_Box_Out,
        ALUOut_Out,
        EPC_Out,
        mux_PC_Out
    );

    Control_Unit control_unit(
        clk,
        reset,
        OPCODE,
        IMMEDIATE,
        OVERFLOW,
        DivZero,

        mux_MemWD_selector,
        mux_divSrcA_selector,
        mux_high_low_selector,
        mux_ALU_Out_selector,
        mux_ShiftSrc_selector,
        mux_ShiftN_selector,

        mux_ALU_A_selector,            
        mux_PC_selector,              
        mux_WR_Registers_selector,    
        
        mux_ALU_B_selector,            
        mux_MemAddr_selector,         
        mux_WD_Registers_selector,    

        EPC_Load,
        MDR_Load,
        IR_Load,
        HL_Load,
        A_Load,
        B_Load,
        ALUOut_Load,

        Reg_WR,
        Store_Size_selector,
        Load_Size_selector,
        Memory_WR,

        PCWrite,
        PCWriteCond,
        Flag_selector,
        Branch_selector,

        ALU_selector,
        Shift_selector,
        
        MultInit,
        DivInit
    );

endmodule