/* TODO'S:
    X 1. Listar entradas 
    X 2. Listar as saidas por tipo de mux (num. de entradas por mux)
    X 3. " saidas para registradores
    X 4. " saidas para componentes fornecidos
    X 5. " saidas para componentes criados
    X 6.  Definir parametros e variaveis para controlar os estados de cada OpCode
    7. Logica de estados para IF e ID
    8. Logica de estados por OpCode
        8.1 Logica de estados de excecao (OBS.: Overflow tmb incluido em shift's)
    10. 
    9. Revisar 7 e 8 ate ter certeza

    10. Revisitar estados de OVERFLOW, OPCODE 404 e DIV0
*/

/*
    Faltam os estados das instruções:
    X 1. xchg rs, rt
    X 2. divm rt, offset(rs)
    X 3. or rd, rs, rt
*/


module Control_Unit (

//INPUT PORTS
input wire          clk,
input wire          Reset_In,
input wire [5:0]    OPCODE,
input wire [15:0]   IMMEDIATE,
input wire          Overflow,
input wire          DivZero,

//OUTPUT PORTS
//Muxs (até 2 entradas)
output reg          WriteMemoSrc,
output reg          DivOp,
output reg          writeHL,
output reg          HLSrc,
output reg          ALUOutSrc,
output reg          ShiftSrc,
output reg          ShiftAmt,

//Muxs (até 4 entradas)
output reg [1:0]    ALUSrcA,            //4 entradas
output reg [1:0]    PCSource,              //4 entradas
output reg [1:0]    RegDst,    //4 entradas

//Muxs (até 8 entradas)
output reg [2:0]    ALUSrcB,            //5 entradas
output reg [2:0]    AddressCtrl,         //7 entradas
output reg [2:0]    RegSrc,    //8 entradas

//Registers
output reg          EPC_Load,
output reg          MDR_Load,
output reg          IRWrite,
output reg          writeHL,
output reg          A_Load,
output reg          B_Load,
output reg          ALUOut_Load,

//Write and Read Controllers
output reg          RegWrite,
output reg          StoreSizeCtrl,
output reg [1:0]    LStoreSizeCtrl,
output reg          MemWR,

//Controlador Controllers
output reg          PCWrite,
output reg          PCWriteCond,              //Antigo PCWriteCond
output reg          FlagOption,
output reg          BranchOption,

//Special Controllers
output reg [2:0]    ALU,
output reg [2:0]    Shift,

//Mult Controller
output reg          MultInit,
//Div Controller
output reg          DivInit

);

//VARIABLES

reg [5:0] states; //(6 bits para representar o estado atual)
reg [4:0] counter; //(5 bit para representar o clk atual em um dado estado)
reg [5:0] Funct;
assign Funct = IMMEDIATE[5:0];

//STATE PARAMETERS

parameter state_Reset       =       6'b000000;
parameter state_Fetch       =       6'b000001;
parameter state_Decode      =       6'b000010;
parameter state_Overflow    =       6'b000011;
parameter state_Opcode404   =       6'b000100;
parameter state_Div0        =       6'b000101;

parameter state_Add         =       6'b000110;
parameter state_And         =       6'b000111;
parameter state_Div         =       6'b001000;
parameter state_Mult        =       6'b001001;
parameter state_Jr          =       6'b001010;
parameter state_Mfhi        =       6'b001011;
parameter state_Mflo        =       6'b001100;
parameter state_Sll         =       6'b001101;
parameter state_Sllv        =       6'b001110;
parameter state_Slt         =       6'b001111;
parameter state_Sra         =       6'b010000;
parameter state_Srav        =       6'b010001;
parameter state_Srl         =       6'b010010;
parameter state_Sub         =       6'b010011;
parameter state_Break       =       6'b010100;
parameter state_RTE         =       6'b010101;
parameter state_Or          =       6'b010110;
parameter state_Xchg        =       6'b101000;

parameter state_Addi        =       6'b010111;
parameter state_Addiu       =       6'b011000;
parameter state_Beq         =       6'b011001;
parameter state_Bne         =       6'b011010;
parameter state_Ble         =       6'b011011;
parameter state_Bgt         =       6'b011100;
parameter state_Divm        =       6'b011101;
parameter state_Lb          =       6'b011110;
parameter state_Lh          =       6'b011111;
parameter state_Lui         =       6'b100000;
parameter state_Lw          =       6'b100001;
parameter state_Sb          =       6'b100010;
parameter state_Sh          =       6'b100011;
parameter state_Slti        =       6'b100100;
parameter state_Sw          =       6'b100101;

parameter state_J           =       6'b100110;
parameter state_Jal         =       6'b100111;

parameter state_MultDivRun  =       6'b101000;

//Opcodes (istruction type)
parameter Op_Type_r         =       6'b000000;
parameter Op_Addi           =       6'b001000;
parameter Op_Addiu          =       6'b001001;
parameter Op_Beq            =       6'b000100;
parameter Op_Bne            =       6'b000101;
parameter Op_Ble            =       6'b000110;
parameter Op_Bgt            =       6'b000111;
parameter Op_Divm           =       6'b000001;
parameter Op_Lb             =       6'b100000;
parameter Op_Lh             =       6'b100001;
parameter Op_Lui            =       6'b001111;
parameter Op_Lw             =       6'b100011;
parameter Op_Sb             =       6'b101000;
parameter Op_Sh             =       6'b101001;
parameter Op_Slti           =       6'b001010; 
parameter Op_Sw             =       6'b101011;
parameter Op_J              =       6'b000010;
parameter Op_Jal            =       6'b000011;

//Funct of type R
parameter Funct_Add         =       6'b100000;
parameter Funct_And         =       6'b100100;
parameter Funct_Or          =       6'b100101;
parameter Funct_Div         =       6'b011010;
parameter Funct_Mult        =       6'b011000;
parameter Funct_Jr          =       6'b001000;
parameter Funct_Mfhi        =       6'b010000;
parameter Funct_Mflo        =       6'b010010; 
parameter Funct_Sll         =       6'b000000;
parameter Funct_Sllv        =       6'b000100;
parameter Funct_Slt         =       6'b101010;
parameter Funct_Sra         =       6'b000011;
parameter Funct_Srav        =       6'b000111;
parameter Funct_Srl         =       6'b000010;
parameter Funct_Sub         =       6'b100010;
parameter Funct_Break       =       6'b001101; 
parameter Funct_RTE         =       6'b010011;
parameter Funct_Xchg        =       6'b000101;


initial begin
    states                =   state_Reset;
end

always @(posedge clk) begin
    //RESET
    if ((Reset_In == 1'b1) || state == state_Reset) begin
        RegDst              =   2'b10;  
        RegSrc              =   3'b000; 
        RegWrite            =   1'b1; 
        EPC_Load            =   1'b0;
        MDR_Load            =   1'b0;
        IRWrite             =   1'b0;
        writeHL             =   1'b0;
        A_Load              =   1'b0;
        B_Load              =   1'b0;
        ALUOut_Load         =   1'b0;
        MemWR               =   1'b0;
        IRWrite             =   1'b1;        
        PCWrite             =   1'b0;
        PCWriteCond         =   1'b0;
        FlagOption          =   1'b0;
        BranchOption        =   1'b0;

        //next state
        states = state_Fetch;
        counter = 5'b00000;
    end else begin
        AddressCtrl         =   3'b000;
        ALUSrcA             =   2'b00; 
        ALUSrcB             =   3'b000; 
        ALU                 =   3'b00;
        MDR_Load            =   1'b0;
        EPC_Load            =   1'b0;
        IRWrite             =   1'b0;
        writeHL             =   1'b0;
        A_Load              =   1'b0;
        B_Load              =   1'b0;
        ALUOut_Load         =   1'b0;
        MemWR               =   1'b0;
        IRWrite             =   1'b0;
        PCWrite             =   1'b0;
        PCWriteCond         =   1'b0;
        FlagOption          =   1'b0;
        BranchOption        =   1'b0;
        
        MultInit            =   1'b0;
        DivInit             =   1'b0;
        case (states) //descobrir qual estado se esta para tornar o output adequado
            //FETCH - revised
            state_Fetch: begin
                if (counter == 5'b00000 || counter == 5'b00001) begin
                    AddressCtrl         =   3'b000; ///
                    ALUSrcA             =   2'b00; 
                    ALUSrcB             =   2'b01; 
                    ALU                 =   3'b001;
                    MDR_Load            =   1'b0;
                    EPC_Load            =   1'b0;
                    IRWrite             =   1'b0;
                    writeHL             =   1'b0;
                    A_Load              =   1'b0;
                    B_Load              =   1'b0;
                    ALUOut_Load         =   1'b1;
                    MemWR               =   1'b0; ///
                    IRWrite             =   1'b0;
                    PCWrite             =   1'b0;
                    PCWriteCond         =   1'b0;
                    FlagOption          =   1'b0;
                    BranchOption        =   1'b0;
                    
                    MultInit            =   1'b0;
                    DivInit             =   1'b0;

                    //next state
                    states = state_Fetch;
                    counter = counter + 5'b00001;
                end else if (counter == 5'b00010) begin //IR Write State
                    PCSource            =   2'b00; ////
                    EPC_Load            =   1'b0;
                    MDR_Load            =   1'b0;
                    ALUSrcA             =   2'b00; 
                    ALUSrcB             =   2'b01; 
                    ALU                 =   3'b001;
                    ALUOutSrc           =   1'b1;
                    IRWrite             =   1'b1; ////
                    writeHL             =   1'b0;
                    A_Load              =   1'b0;
                    B_Load              =   1'b0;
                    ALUOut_Load         =   1'b0;
                    MemWR               =   1'b0;
                    PCWrite             =   1'b1; ////
                    PCWriteCond         =   1'b0;
                    FlagOption          =   1'b0;
                    BranchOption        =   1'b0;
                    
                    MultInit            =   1'b0;
                    DivInit             =   1'b0;

                    //next state
                    states = state_Decode;
                    counter = 5'b00000;
                    end
            end 

            //DECODE - revised
            state_Decode: begin
                ALUSrcA             =   2'b00; ////
                ALUSrcB             =   2'b11; ////
                ALU                 =   3'b001; ////
                ALUOutSrc           =   1'b1; ////
                EPC_Load            =   1'b0;
                MDR_Load            =   1'b0;
                IRWrite             =   1'b0;
                writeHL             =   1'b0;
                A_Load              =   1'b0;
                B_Load              =   1'b0;
                ALUOut_Load         =   1'b1; ////
                MemWR               =   1'b0;
                IRWrite             =   1'b0;
                PCWrite             =   1'b0;
                PCWriteCond         =   1'b0;
                FlagOption          =   1'b0;
                BranchOption        =   1'b0;
                
                MultInit            =   1'b0;
                DivInit             =   1'b0;
                //next state
                counter = 5'b00000;
                case (OPCODE) //Analisando OPCODE da operacao atual para definir o proximo estado
                    //OP Tipo R
                    Op_Type_r: begin
                        case (Funct) //Analisando campo Funct do tipo R
                            //Funct ADD
                            Funct_Add: begin
                                states = state_Add;
                            end

                            //Funct AND
                            Funct_And: begin
                                states = state_And;
                            end

                            //Funct DIV
                            Funct_Div: begin
                                states = state_Div;
                            end

                            //Funct MULT
                            Funct_Mult: begin
                                states = state_Mult;
                            end

                            //Funct JR
                            Funct_Jr: begin
                                states = state_Jr;
                            end

                            //Funct MFHI
                            Funct_Mfhi: begin
                                states = state_Mfhi;
                            end

                            //Funct MFLO
                            Funct_Mflo: begin
                                states = state_Mflo;
                            end

                            //Funct SLL
                            Funct_Sll: begin
                                states = state_Sll;
                            end
                            
                            //Funct SLLV
                            Funct_Sllv: begin
                                states = state_Sllv;
                            end

                            //Funct SLT
                            Funct_Slt: begin
                                states = state_Slt;
                            end

                            //Funct SRA
                            Funct_Sra: begin
                                states = state_Sra;
                            end

                            //Funct SRAV
                            Funct_Srav: begin
                                states = state_Srav;
                            end

                            //Funct SRL
                            Funct_Srl: begin
                                states = state_Srl;
                            end

                            //Funct SUB
                            Funct_Sub: begin
                                states = state_Sub;
                            end

                            //Funct BREAK
                            Funct_Break: begin
                                states = state_Break;
                            end

                            //Funct RTE
                            Funct_RTE: begin
                                states = state_RTE;
                            end

                            //Funct OR
                            Funct_Or: begin
                                states = state_Or;
                            end

                            //Funct XCHG
                            Funct_Xchg: begin
                                states = state_Xchg;
                            end

                            default: //erro de opcode
                                states = state_Opcode404;
                        endcase
                    end

                    //Op ADDI
                    Op_Addi: begin
                        states = state_Addi;
                    end

                    //Op ADDIU
                    Op_Addiu: begin
                        states = state_Addiu;
                    end

                    //Op BEQ
                    Op_Beq: begin
                        states = state_Beq;
                    end

                    //Op BNE
                    Op_Bne: begin
                        states = state_Bne;
                    end

                    //Op BLE
                    Op_Ble: begin
                        states = state_Ble;
                    end

                    //Op BGT
                    Op_Bgt: begin
                        states = state_Bgt;
                    end

                    //Op Divm
                    Op_Divm: begin
                        states = state_Divm;
                    end

                    //Op LB
                    Op_Lb: begin
                        states = state_Lb;
                    end

                    //Op LH
                    Op_Lh: begin
                        states = state_Lh;
                    end

                    //Op LUI
                    Op_Lui: begin
                        states = state_Lui;
                    end

                    //Op LW
                    Op_Lw: begin
                        states = state_Lw;
                    end

                    //Op SB
                    Op_Sb: begin
                        states = state_Sb;
                    end

                    //Op SH
                    Op_Sh: begin
                        states = state_Sh;
                    end

                    //Op SLTI
                    Op_Slti: begin
                        states = state_Slti;
                    end

                    //Op SW
                    Op_Sw: begin
                        states = state_Sw;
                    end

                    //Op J
                    Op_J: begin
                        states = state_J;
                    end

                    //Op JAL
                    Op_Jal: begin
                        states = state_Jal;
                    end

                    default:
                        states = state_Opcode404;
                    endcase
                end

            //OVERFLOW
            state_Overflow: begin
                if (counter == 5'b00000 || counter == 5'b00001 || counter == 5'b00010) begin
                    AddressCtrl         =   3'b011; ////
                    EPC_Load            =   1'b0;
                    MDR_Load            =   1'b0;
                    IRWrite             =   1'b0;
                    writeHL             =   1'b0;
                    A_Load              =   1'b0;
                    B_Load              =   1'b0;
                    ALUOut_Load         =   1'b0;
                    MemWR               =   1'b0;
                    IRWrite             =   1'b0;
                    PCWrite             =   1'b0;
                    PCWriteCond         =   1'b0;
                    FlagOption          =   1'b0;
                    BranchOption        =   1'b0;
                    
                    MultInit            =   1'b0;
                    DivInit             =   1'b0;

                    //next state
                    states = state_Overflow;
                    counter = counter + 5'b00001;
                end else if (counter == 5'b00011) begin
                    EPC_Load            =   1'b1; ////
                    MDR_Load            =   1'b1; ////
                    IRWrite             =   1'b0;
                    writeHL             =   1'b0;
                    A_Load              =   1'b0;
                    B_Load              =   1'b0;
                    ALUOut_Load         =   1'b0;
                    MemWR               =   1'b0;
                    IRWrite             =   1'b0;
                    PCWrite             =   1'b0;
                    PCWriteCond         =   1'b0;
                    FlagOption          =   1'b0;
                    BranchOption        =   1'b0;
                    
                    MultInit            =   1'b0;
                    DivInit             =   1'b0;

                    //next state
                    states = state_Overflow;
                    counter = counter + 5'b00001;
                end else if (counter == 5'b00100) begin
                    ALUSrcA            =   2'b10; ////
                    ALUSrcB            =   3'b010; ////
                    PCSource           =   2'b01; ////
                    ALU                =   3'b001; ////
                    EPC_Load           =   1'b0;
                    MDR_Load           =   1'b0;
                    IRWrite            =   1'b0;
                    writeHL            =   1'b0;
                    A_Load             =   1'b0;
                    B_Load             =   1'b0;
                    ALUOut_Load        =   1'b0;
                    MemWR              =   1'b0;
                    IRWrite            =   1'b0;
                    PCWrite            =   1'b1; ////
                    PCWriteCond        =   1'b0;
                    FlagOption         =   1'b0;
                    BranchOption       =   1'b0;
                    
                    MultInit            =   1'b0;
                    DivInit             =   1'b0;

                    //next state
                    states = state_Fetch;
                    counter = 5'b00000;
                end
            end

            //OPCODE INEXISTENTE
            state_Opcode404: begin
                if (counter == 5'b00000 || counter == 5'b00001 || counter == 5'b00010) begin
                    AddressCtrl         =   3'b010; ////
                    EPC_Load            =   1'b0;
                    MDR_Load            =   1'b0;
                    IRWrite             =   1'b0;
                    writeHL             =   1'b0;
                    A_Load              =   1'b0;
                    B_Load              =   1'b0;
                    ALUOut_Load         =   1'b0;
                    MemWR               =   1'b0;
                    IRWrite             =   1'b0;
                    PCWrite             =   1'b0;
                    PCWriteCond         =   1'b0;
                    FlagOption          =   1'b0;
                    BranchOption        =   1'b0;
                    
                    MultInit            =   1'b0;
                    DivInit             =   1'b0;

                    //next state
                    states = state_Opcode404;
                    counter = counter + 5'b00001;
                end else if (counter == 5'b00011) begin
                    EPC_Load            =   1'b1; ////
                    MDR_Load            =   1'b1; ////
                    IRWrite             =   1'b0;
                    writeHL             =   1'b0;
                    A_Load              =   1'b0;
                    B_Load              =   1'b0;
                    ALUOut_Load         =   1'b0;
                    MemWR               =   1'b0;
                    IRWrite             =   1'b0;
                    PCWrite             =   1'b0;
                    PCWriteCond         =   1'b0;
                    FlagOption          =   1'b0;
                    BranchOption        =   1'b0;
                    
                    MultInit            =   1'b0;
                    DivInit             =   1'b0;

                    //next state
                    states = state_Opcode404;
                    counter = counter + 5'b00001;
                end else if (counter == 5'b00100) begin
                    ALUSrcA            =   2'b10; ////
                    ALUSrcB            =   3'b010; ////
                    PCSource           =   2'b01; ////
                    ALU                =   3'b001; ////
                    EPC_Load           =   1'b0;
                    MDR_Load           =   1'b0;
                    IRWrite            =   1'b0;
                    writeHL            =   1'b0;
                    A_Load             =   1'b0;
                    B_Load             =   1'b0;
                    ALUOut_Load        =   1'b0;
                    MemWR              =   1'b0;
                    IRWrite            =   1'b0;
                    PCWrite            =   1'b1; ////
                    PCWriteCond        =   1'b0;
                    FlagOption         =   1'b0;
                    BranchOption       =   1'b0;
                    
                    MultInit            =   1'b0;
                    DivInit             =   1'b0;

                    //next state
                    states = state_Fetch;
                    counter = 5'b00000;
                end
            end

            //DIVISAO POR 0
            state_Div0: begin
                if (counter == 5'b00000 || counter == 5'b00001 || counter == 5'b00010) begin
                    AddressCtrl         =   3'b100; ////
                    EPC_Load            =   1'b0;
                    MDR_Load            =   1'b0;
                    IRWrite             =   1'b0;
                    writeHL             =   1'b0;
                    A_Load              =   1'b0;
                    B_Load              =   1'b0;
                    ALUOut_Load         =   1'b0;
                    MemWR               =   1'b0;
                    IRWrite             =   1'b0;
                    PCWrite             =   1'b0;
                    PCWriteCond         =   1'b0;
                    FlagOption          =   1'b0;
                    BranchOption        =   1'b0;
                    
                    MultInit            =   1'b0;
                    DivInit             =   1'b0;

                    //next state
                    states = state_Div0;
                    counter = counter + 5'b00001;
                end else if (counter == 5'b00011) begin
                    EPC_Load            =   1'b1; ////
                    MDR_Load            =   1'b1; ////
                    IRWrite             =   1'b0;
                    writeHL             =   1'b0;
                    A_Load              =   1'b0;
                    B_Load              =   1'b0;
                    ALUOut_Load         =   1'b0;
                    MemWR               =   1'b0;
                    IRWrite             =   1'b0;
                    PCWrite             =   1'b0;
                    PCWriteCond         =   1'b0;
                    FlagOption          =   1'b0;
                    BranchOption        =   1'b0;
                    
                    MultInit            =   1'b0;
                    DivInit             =   1'b0;

                    //next state
                    states = state_Div0;
                    counter = counter + 5'b00001;
                end else if (counter == 5'b00100) begin
                    ALUSrcA            =   2'b10; ////
                    ALUSrcB            =   3'b010; ////
                    PCSource           =   2'b01; ////
                    ALU                =   3'b001; ////
                    EPC_Load           =   1'b0;
                    MDR_Load           =   1'b0;
                    IRWrite            =   1'b0;
                    writeHL            =   1'b0;
                    A_Load             =   1'b0;
                    B_Load             =   1'b0;
                    ALUOut_Load        =   1'b0;
                    MemWR              =   1'b0;
                    IRWrite            =   1'b0;
                    PCWrite            =   1'b1; ////
                    PCWriteCond        =   1'b0;
                    FlagOption         =   1'b0;
                    BranchOption       =   1'b0;
                    
                    MultInit           =   1'b0;
                    DivInit            =   1'b0;

                    //next state
                    states = state_Fetch;
                    counter = 5'b00000;
                end
            end
            
            //ADD - revised
            state_Add: begin
                if (counter == 5'b00000) begin
                    ALUSrcA            =   2'b01; ////
                    ALUSrcB            =   3'b000; ////
                    ALU                =   3'b001; ////
                    ALUOutSrc          =   2'b01; ////
                    ALUOut_Load        =   1'b1; ////
                    EPC_Load           =   1'b0;
                    MDR_Load           =   1'b0;
                    IRWrite            =   1'b0;
                    writeHL            =   1'b0;
                    A_Load             =   1'b0;
                    B_Load             =   1'b0;
                    MemWR              =   1'b0;
                    IRWrite            =   1'b0;
                    PCWrite            =   1'b0;
                    PCWriteCond        =   1'b0;
                    FlagOption         =   1'b0;
                    BranchOption       =   1'b0;
                    
                    MultInit           =   1'b0;
                    DivInit            =   1'b0;
                    
                    //next state
                    states = state_Add;
                    counter = counter + 5'b00001;
                end else if (counter == 5'b00001) begin
                    if (Overflow) begin
                        //Erro de overflow so deve ser analisado apos o calculo
                        states = state_Overflow;
                        counter = 5'b00000;
                    end else begin
                        RegDst            =   2'b11; ////
                        RegSrc            =   3'b101; ////
                        EPC_Load          =   1'b0;
                        MDR_Load          =   1'b0;
                        IRWrite           =   1'b0;
                        writeHL           =   1'b0;
                        A_Load            =   1'b0;
                        B_Load            =   1'b0;
                        ALUOut_Load       =   1'b0;
                        MemWR             =   1'b0;
                        IRWrite           =   1'b0;
                        RegWrite          =   1'b1; ////
                        PCWrite           =   1'b0;
                        PCWriteCond       =   1'b0;
                        FlagOption        =   1'b0;
                        BranchOption      =   1'b0;
                        
                        MultInit          =   1'b0;
                        DivInit           =   1'b0;

                        //next state
                        states            = state_Fetch;
                        counter           = 5'b00000;
                    end
                end
            end

            //AND - revised
            state_And: begin
                if (counter == 5'b00000) begin
                    ALUSrcA            =   2'b01; ////
                    ALUSrcB            =   3'b000; ////
                    ALU                =   3'b011; ////
                    ALUOutSrc          =   2'b01; ////
                    ALUOut_Load        =   1'b1; ////
                    EPC_Load           =   1'b0;
                    MDR_Load           =   1'b0;
                    IRWrite            =   1'b0;
                    writeHL            =   1'b0;
                    A_Load             =   1'b0;
                    B_Load             =   1'b0;
                    MemWR              =   1'b0;
                    IRWrite            =   1'b0;
                    PCWrite            =   1'b0;
                    PCWriteCond        =   1'b0;
                    FlagOption         =   1'b0;
                    BranchOption       =   1'b0;
                    
                    MultInit           =   1'b0;
                    DivInit            =   1'b0;

                    //next state
                    states = state_And;
                    counter = counter + 5'b00001;
                end else if (counter == 5'b00001) begin
                    RegDst            =   2'b11; ////
                    RegSrc            =   3'b101; ////
                    EPC_Load          =   1'b0;
                    MDR_Load          =   1'b0;
                    IRWrite           =   1'b0;
                    writeHL           =   1'b0;
                    A_Load            =   1'b0;
                    B_Load            =   1'b0;
                    ALUOut_Load       =   1'b0;
                    MemWR             =   1'b0;
                    IRWrite           =   1'b0;
                    RegWrite          =   1'b1; ////
                    PCWrite           =   1'b0;
                    PCWriteCond       =   1'b0;
                    FlagOption        =   1'b0;
                    BranchOption      =   1'b0;
                    
                    MultInit          =   1'b0;
                    DivInit           =   1'b0;

                    //next state
                    states            = state_Fetch;
                    counter           = 5'b00000;
                end
            end

            //OR - revised
            state_Or: begin
                if (counter == 5'b00000) begin
                    ALUSrcA            =   2'b10; ////
                    ALUSrcB            =   3'b100; ////
                    ALU                =   3'b011; ////
                    ALUOutSrc          =   2'b10; ////
                    ALUOut_Load        =   1'b1; ////
                    EPC_Load           =   1'b0;
                    MDR_Load           =   1'b0;
                    IRWrite            =   1'b0;
                    writeHL            =   1'b0;
                    A_Load             =   1'b0;
                    B_Load             =   1'b0;
                    MemWR              =   1'b0;
                    IRWrite            =   1'b0;
                    PCWrite            =   1'b0;
                    PCWriteCond        =   1'b0;
                    FlagOption         =   1'b0;
                    BranchOption       =   1'b0;
                    
                    MultInit           =   1'b0;
                    DivInit            =   1'b0;

                    //next state
                    states = state_And;
                    counter = counter + 5'b00001;
                end else if (counter == 5'b00001) begin
                    RegDst            =   2'b11; ////
                    RegSrc            =   3'b101; ////
                    EPC_Load          =   1'b0;
                    MDR_Load          =   1'b0;
                    IRWrite           =   1'b0;
                    writeHL           =   1'b0;
                    A_Load            =   1'b0;
                    B_Load            =   1'b0;
                    ALUOut_Load       =   1'b0;
                    MemWR             =   1'b0;
                    IRWrite           =   1'b0;
                    RegWrite          =   1'b1; ////
                    PCWrite           =   1'b0;
                    PCWriteCond       =   1'b0;
                    FlagOption        =   1'b0;
                    BranchOption      =   1'b0;
                    
                    MultInit          =   1'b0;
                    DivInit           =   1'b0;

                    //next state
                    states            = state_Fetch;
                    counter           = 5'b00000;
                end
            end

            //DIV - revised
            state_Div: begin
                ALUSrcA             =   2'b00;
                ALUSrcB             =   2'b00;
                ALU                 =   3'b000;
                PCSource            =   2'b00;
                EPC_Load            =   1'b0;
                MDR_Load            =   1'b0;
                IRWrite             =   1'b0;
                writeHL             =   1'b0; ////
                HLSrc               =   1'b0; ////
                A_Load              =   1'b0;
                B_Load              =   1'b0;
                ALUOut_Load         =   1'b0; 
                MemWR               =   1'b0;
                IRWrite             =   1'b0;
                PCWrite             =   1'b0;
                PCWriteCond         =   1'b0;
                FlagOption          =   1'b0;
                BranchOption        =   1'b0;
                
                MultInit            =   1'b0;
                DivInit             =   1'b1; ////

                // DivZero = 0 -> Error detection
                if (!DivZero) begin
                    DivInit             =   1'b0;
                    states              =   state_Div0;
                end else begin
                    counter             =   5'b00000; ////
                    states              =   state_MultDivRun;
                end
            end

            state_MultDivRun: begin
                if (DivInit || MultInit) begin
                    if (DivInit && !DivZero) begin
                        states = state_Div0;
                        DivInit = 1'b0;
                    end else begin
                        states = state_MultDivRun;
                        DivInit = 1'b0;
                        MultInit = 1'b0;
                    end
                end else if (counter == 5'b11111) begin
                    writeHL = 1'b1;
                    states = state_Fetch;
                end else begin
                    states = state_MultDivRun;
                    counter = counter + 5'b00001;
                end
            end

            //MULT - revised
            state_Mult: begin
                ALUSrcA             =   2'b00;
                ALUSrcB             =   2'b00;
                ALU                 =   3'b000;
                PCSource            =   2'b00;
                writeHL             =   1'b0; ////
                HLSrc               =   1'b1; ////
                EPC_Load            =   1'b0;
                MDR_Load            =   1'b0;
                IRWrite             =   1'b0;
                A_Load              =   1'b0;
                B_Load              =   1'b0;
                ALUOut_Load         =   1'b0; 
                MemWR               =   1'b0;
                IRWrite             =   1'b0;
                PCWrite             =   1'b0;
                PCWriteCond         =   1'b0;
                FlagOption          =   1'b0;
                BranchOption        =   1'b0;
                
                MultInit            =   1'b1;
                DivInit             =   1'b0;

                counter = 5'b00000;
                states = state_MultDivRun;
            end
            
            //JR - revised
            state_Jr: begin
                if (counter == 5'b00000) begin
                    ALUSrcA            =   2'b01; ////
                    ALUSrcB            =   3'b000; ////
                    ALU                =   3'b000; ////
                    PCSource           =   2'b00; ////
                    EPC_Load           =   1'b0;
                    MDR_Load           =   1'b0;
                    IRWrite            =   1'b0;
                    writeHL            =   1'b0;
                    A_Load             =   1'b0;
                    B_Load             =   1'b0;
                    ALUOut_Load        =   1'b0; 
                    MemWR              =   1'b0;
                    IRWrite            =   1'b0;
                    PCWrite            =   1'b1; ////
                    PCWriteCond        =   1'b0;
                    FlagOption         =   1'b0;
                    BranchOption       =   1'b0;
                    
                    MultInit           =   1'b0;
                    DivInit            =   1'b0;

                    //next state
                    states = state_Fetch;
                    counter = 5'b00000;
                end 
            end

            //MFHI - revised
            state_Mfhi: begin
                if (counter == 5'b00000) begin
                    RegDst              =   2'b11; ////
                    RegSrc              =   3'b111; ////
                    EPC_Load            =   1'b0;
                    MDR_Load            =   1'b0;
                    IRWrite             =   1'b0;
                    writeHL             =   1'b0;
                    A_Load              =   1'b0;
                    B_Load              =   1'b0;
                    ALUOut_Load         =   1'b0;
                    MemWR               =   1'b0;
                    RegWrite            =   1'b1; ////
                    PCWrite             =   1'b0;
                    PCWriteCond         =   1'b0;
                    FlagOption          =   1'b0;
                    BranchOption        =   1'b0;
                    
                    MultInit            =   1'b0;
                    DivInit             =   1'b0;

                    //next state
                    states = state_Fetch;
                    counter = 5'b00000;
                end
            end

            //MFLO - revised
            state_Mflo: begin
                if (counter == 5'b00000) begin
                    RegDst              =   2'b11; ////
                    RegSrc              =   3'b110; ////
                    EPC_Load            =   1'b0;
                    MDR_Load            =   1'b0;
                    IRWrite             =   1'b0;
                    writeHL             =   1'b0;
                    A_Load              =   1'b0;
                    B_Load              =   1'b0;
                    ALUOut_Load         =   1'b0;
                    MemWR               =   1'b0;
                    RegWrite            =   1'b1; ////
                    PCWrite             =   1'b0;
                    PCWriteCond         =   1'b0;
                    FlagOption          =   1'b0;
                    BranchOption        =   1'b0;
                    
                    MultInit            =   1'b0;
                    DivInit             =   1'b0;

                    //next state
                    states = state_Fetch;
                    counter = 5'b00000;
                end
            end

            //SLL
            state_Sll: begin
                if (counter == 5'b00000) begin
                    ShiftSrc         =   1'b1; ////
                    ShiftAmt               =   1'b1; ////
                    Shift               =   3'b001; ////
                    EPC_Load            =   1'b0;
                    MDR_Load            =   1'b0;
                    IRWrite             =   1'b0;
                    writeHL            =   1'b0;
                    A_Load              =   1'b0;
                    B_Load              =   1'b0;
                    ALUOut_Load         =   1'b0;
                    MemWR           =   1'b0;
                    IRWrite              =   1'b0;
                    PCWrite             =   1'b0;
                    PCWriteCond               =   1'b0;
                    FlagOption               =   1'b0;
                    BranchOption               =   1'b0;

                    MultInit            =   1'b0;
                    DivInit             =   1'b0;

                    //next state
                    states = state_Sll;
                    counter = counter + 5'b00001;
                end else if (counter == 5'b00001) begin
                    RegDst    =   2'b11; ////
                    RegSrc    =   3'b101; ////
                    Shift               =   3'b010; ////
                    EPC_Load            =   1'b0;
                    MDR_Load            =   1'b0;
                    IRWrite             =   1'b0;
                    writeHL            =   1'b0;
                    A_Load              =   1'b0;
                    B_Load              =   1'b0;
                    ALUOut_Load         =   1'b0;
                    MemWR           =   1'b0;
                    IRWrite              =   1'b0; ////
                    PCWrite             =   1'b0;
                    PCWriteCond               =   1'b0;
                    FlagOption               =   1'b0;
                    BranchOption               =   1'b0;
                    
                    MultInit            =   1'b0;
                    DivInit             =   1'b0;

                    //next state
                    states = state_Sll;
                    counter = counter + 5'b00001;
                end else if (counter == 5'b00010) begin
                    Shift               =   3'b000; ////
                    EPC_Load            =   1'b0;
                    MDR_Load            =   1'b0;
                    IRWrite             =   1'b0;
                    writeHL            =   1'b0;
                    A_Load              =   1'b0;
                    B_Load              =   1'b0;
                    ALUOut_Load         =   1'b0;
                    MemWR           =   1'b0;
                    IRWrite              =   1'b1;
                    PCWrite             =   1'b0;
                    PCWriteCond               =   1'b0;
                    FlagOption               =   1'b0;
                    BranchOption               =   1'b0;
                    
                    MultInit            =   1'b0;
                    DivInit             =   1'b0;

                    //next state
                    states = state_Fetch;
                    counter = 5'b00000;
                end
            end

            //SLLV
            state_Sllv: begin
                if (counter == 5'b00000) begin
                    ShiftSrc         =   1'b0; ////
                    ShiftAmt               =   1'b0; ////
                    Shift               =   3'b001; ////
                    EPC_Load            =   1'b0;
                    MDR_Load            =   1'b0;
                    IRWrite             =   1'b0;
                    writeHL            =   1'b0;
                    A_Load              =   1'b0;
                    B_Load              =   1'b0;
                    ALUOut_Load         =   1'b0;
                    MemWR           =   1'b0;
                    IRWrite              =   1'b0;
                    PCWrite             =   1'b0;
                    PCWriteCond               =   1'b0;
                    FlagOption               =   1'b0;
                    BranchOption               =   1'b0;
                    
                    MultInit            =   1'b0;
                    DivInit             =   1'b0;

                    //next state
                    states = state_Sllv;
                    counter = counter + 5'b00001;
                end else if (counter == 5'b00001) begin
                    RegDst    =   2'b11; ////
                    RegSrc    =   3'b101; ////
                    Shift               =   3'b010; ////
                    EPC_Load            =   1'b0;
                    MDR_Load            =   1'b0;
                    IRWrite             =   1'b0;
                    writeHL            =   1'b0;
                    A_Load              =   1'b0;
                    B_Load              =   1'b0;
                    ALUOut_Load         =   1'b0;
                    MemWR           =   1'b0;
                    IRWrite              =   1'b0; 
                    PCWrite             =   1'b0;
                    PCWriteCond               =   1'b0;
                    FlagOption               =   1'b0;
                    BranchOption               =   1'b0;
                    
                    MultInit            =   1'b0;
                    DivInit             =   1'b0;

                    //next state
                    states = state_Sllv;
                    counter = counter + 5'b00001;
                end else if (counter == 5'b00010) begin
                    Shift               =   3'b000; ////
                    EPC_Load            =   1'b0;
                    MDR_Load            =   1'b0;
                    IRWrite             =   1'b0;
                    writeHL            =   1'b0;
                    A_Load              =   1'b0;
                    B_Load              =   1'b0;
                    ALUOut_Load         =   1'b0;
                    MemWR           =   1'b0;
                    IRWrite              =   1'b1; //
                    PCWrite             =   1'b0;
                    PCWriteCond               =   1'b0;
                    FlagOption               =   1'b0;
                    BranchOption               =   1'b0;
                    
                    MultInit            =   1'b0;
                    DivInit             =   1'b0;

                    //next state
                    states = state_Fetch;
                    counter = 5'b00000;
                end
            end

            //SLT
            state_Slt: begin
                if (counter == 5'b00000) begin
                    ALUSrcA            =   2'b01; ////
                    ALUSrcB            =   3'b000; ////
                    ALU                 =   3'b111; ////
                    EPC_Load            =   1'b0;
                    MDR_Load            =   1'b0;
                    IRWrite             =   1'b0;
                    writeHL            =   1'b0;
                    A_Load              =   1'b0;
                    B_Load              =   1'b0;
                    ALUOut_Load         =   1'b0;
                    MemWR           =   1'b0;
                    IRWrite              =   1'b0;
                    PCWrite             =   1'b0;
                    PCWriteCond               =   1'b0;
                    FlagOption               =   1'b0;
                    BranchOption               =   1'b0;
                    
                    MultInit            =   1'b0;
                    DivInit             =   1'b0;

                    //next state
                    states = state_Slt;
                    counter = counter + 5'b00001;
                end else if (counter == 5'b00001) begin
                    RegDst    =   2'b11; ////
                    RegSrc    =   3'b110; ////
                    EPC_Load            =   1'b0;
                    MDR_Load            =   1'b0;
                    IRWrite             =   1'b0;
                    writeHL            =   1'b0;
                    A_Load              =   1'b0;
                    B_Load              =   1'b0;
                    ALUOut_Load         =   1'b0;
                    MemWR           =   1'b0;
                    IRWrite              =   1'b1; ////
                    PCWrite             =   1'b0;
                    PCWriteCond               =   1'b0;
                    FlagOption               =   1'b0;
                    BranchOption               =   1'b0;
                    
                    MultInit            =   1'b0;
                    DivInit             =   1'b0;

                    //next state
                    states = state_Fetch;
                    counter = 5'b00000;
                end
            end

            //SRA
            state_Sra: begin
                if (counter == 5'b00000) begin
                    ShiftSrc         =   1'b1; ////
                    ShiftAmt               =   1'b1; ////
                    Shift               =   3'b001; ////
                    EPC_Load            =   1'b0;
                    MDR_Load            =   1'b0;
                    IRWrite             =   1'b0;
                    writeHL            =   1'b0;
                    A_Load              =   1'b0;
                    B_Load              =   1'b0;
                    ALUOut_Load         =   1'b0;
                    MemWR           =   1'b0;
                    IRWrite              =   1'b0;
                    PCWrite             =   1'b0;
                    PCWriteCond               =   1'b0;
                    FlagOption               =   1'b0;
                    BranchOption               =   1'b0;
                    
                    MultInit            =   1'b0;
                    DivInit             =   1'b0;

                    //next state
                    states = state_Sra;
                    counter = counter + 5'b00001;
                end else if (counter == 5'b00001) begin
                    RegDst    =   2'b11; ////
                    RegSrc    =   3'b101; ////
                    Shift               =   3'b100; ////
                    EPC_Load            =   1'b0;
                    MDR_Load            =   1'b0;
                    IRWrite             =   1'b0;
                    writeHL            =   1'b0;
                    A_Load              =   1'b0;
                    B_Load              =   1'b0;
                    ALUOut_Load         =   1'b0;
                    MemWR           =   1'b0;
                    IRWrite              =   1'b0;
                    PCWrite             =   1'b0;
                    PCWriteCond               =   1'b0;
                    FlagOption               =   1'b0;
                    BranchOption               =   1'b0;
                    
                    MultInit            =   1'b0;
                    DivInit             =   1'b0;

                    //next state
                    states = state_Sra;
                    counter = counter + 5'b00001;
                end else if (counter == 5'b00010) begin
                    Shift               =   3'b000; ////
                    EPC_Load            =   1'b0;
                    MDR_Load            =   1'b0;
                    IRWrite             =   1'b0;
                    writeHL            =   1'b0;
                    A_Load              =   1'b0;
                    B_Load              =   1'b0;
                    ALUOut_Load         =   1'b0;
                    MemWR           =   1'b0;
                    IRWrite              =   1'b1; ////
                    PCWrite             =   1'b0;
                    PCWriteCond               =   1'b0;
                    FlagOption               =   1'b0;
                    BranchOption               =   1'b0;
                    
                    MultInit            =   1'b0;
                    DivInit             =   1'b0;

                    //next state
                    states = state_Fetch;
                    counter = 5'b00000;
                end
            end
            
            //SRAV
            state_Srav: begin
                if (counter == 5'b00000) begin//AQUI
                    ShiftSrc         =   1'b0; ////
                    ShiftAmt               =   1'b0; ////
                    Shift               =   3'b001; ////
                    EPC_Load            =   1'b0;
                    MDR_Load            =   1'b0;
                    IRWrite             =   1'b0;
                    writeHL            =   1'b0;
                    A_Load              =   1'b0;
                    B_Load              =   1'b0;
                    ALUOut_Load         =   1'b0;
                    MemWR           =   1'b0;
                    IRWrite              =   1'b0;
                    PCWrite             =   1'b0;
                    PCWriteCond               =   1'b0;
                    FlagOption               =   1'b0;
                    BranchOption               =   1'b0;
                    
                    MultInit            =   1'b0;
                    DivInit             =   1'b0;

                    //next state
                    states = state_Srav;
                    counter = counter + 5'b00001;
                end else if (counter == 5'b00001) begin
                    RegDst    =   2'b11; ////
                    RegSrc    =   3'b101; ////
                    Shift               =   3'b100; ////
                    EPC_Load            =   1'b0;
                    MDR_Load            =   1'b0;
                    IRWrite             =   1'b0;
                    writeHL            =   1'b0;
                    A_Load              =   1'b0;
                    B_Load              =   1'b0;
                    ALUOut_Load         =   1'b0;
                    MemWR           =   1'b0;
                    IRWrite              =   1'b0;//
                    PCWrite             =   1'b0;
                    PCWriteCond               =   1'b0;
                    FlagOption               =   1'b0;
                    BranchOption               =   1'b0;
                    
                    MultInit            =   1'b0;
                    DivInit             =   1'b0;

                    //next state
                    states = state_Srav;
                    counter = counter + 5'b00001;
                end else if (counter == 5'b00010) begin
                    Shift               =   3'b000; ////
                    EPC_Load            =   1'b0;
                    MDR_Load            =   1'b0;
                    IRWrite             =   1'b0;
                    writeHL            =   1'b0;
                    A_Load              =   1'b0;
                    B_Load              =   1'b0;
                    ALUOut_Load         =   1'b0;
                    MemWR           =   1'b0;
                    IRWrite              =   1'b1; ////
                    PCWrite             =   1'b0;
                    PCWriteCond               =   1'b0;
                    FlagOption               =   1'b0;
                    BranchOption               =   1'b0;
                    
                    MultInit            =   1'b0;
                    DivInit             =   1'b0;

                    //next state
                    states = state_Fetch;
                    counter = 5'b00000;
                end
            end

            //SRL
            state_Srl: begin
                if (counter == 5'b00000) begin
                    ShiftSrc         =   1'b1; ////
                    ShiftAmt               =   1'b1; ////
                    Shift               =   3'b001; ////
                    EPC_Load            =   1'b0;
                    MDR_Load            =   1'b0;
                    IRWrite             =   1'b0;
                    writeHL            =   1'b0;
                    A_Load              =   1'b0;
                    B_Load              =   1'b0;
                    ALUOut_Load         =   1'b0;
                    MemWR           =   1'b0;
                    IRWrite              =   1'b0;
                    PCWrite             =   1'b0;
                    PCWriteCond               =   1'b0;
                    FlagOption               =   1'b0;
                    BranchOption               =   1'b0;
                    
                    MultInit            =   1'b0;
                    DivInit             =   1'b0;

                    //next state
                    states = state_Srl;
                    counter = counter + 5'b00001;
                end else if (counter == 5'b00001) begin
                    RegDst    =   2'b11; ////
                    RegSrc    =   3'b101; ////
                    Shift               =   3'b011; ////
                    EPC_Load            =   1'b0;
                    MDR_Load            =   1'b0;
                    IRWrite             =   1'b0;
                    writeHL            =   1'b0;
                    A_Load              =   1'b0;
                    B_Load              =   1'b0;
                    ALUOut_Load         =   1'b0;
                    MemWR           =   1'b0;
                    IRWrite              =   1'b0; ////
                    PCWrite             =   1'b0;
                    PCWriteCond               =   1'b0;
                    FlagOption               =   1'b0;
                    BranchOption               =   1'b0;

                    MultInit            =   1'b0;
                    DivInit             =   1'b0;

                    //next state
                    states = state_Srl;
                    counter = counter + 5'b00001;
                end else if (counter == 5'b00010) begin
                    Shift               =   3'b000; ////
                    EPC_Load            =   1'b0;
                    MDR_Load            =   1'b0;
                    IRWrite             =   1'b0;
                    writeHL            =   1'b0;
                    A_Load              =   1'b0;
                    B_Load              =   1'b0;
                    ALUOut_Load         =   1'b0;
                    MemWR           =   1'b0;
                    IRWrite              =   1'b1; ////
                    PCWrite             =   1'b0;
                    PCWriteCond               =   1'b0;
                    FlagOption               =   1'b0;
                    BranchOption               =   1'b0;

                    MultInit            =   1'b0;
                    DivInit             =   1'b0;

                    //next state
                    states = state_Fetch;
                    counter = 5'b00000;
                end
            end

            //SUB
            state_Sub: begin
                if (counter == 5'b00000) begin
                    ALUSrcA            =   2'b01; ////
                    ALUSrcB            =   3'b000; ////
                    ALU                 =   3'b010; ////
                    EPC_Load            =   1'b0;
                    MDR_Load            =   1'b0;
                    IRWrite             =   1'b0;
                    writeHL            =   1'b0;
                    A_Load              =   1'b0;
                    B_Load              =   1'b0;
                    ALUOut_Load         =   1'b1; ////
                    MemWR           =   1'b0;
                    IRWrite              =   1'b0;
                    PCWrite             =   1'b0;
                    PCWriteCond               =   1'b0;
                    FlagOption               =   1'b0;
                    BranchOption               =   1'b0;
                    
                    MultInit            =   1'b0;
                    DivInit             =   1'b0;

                    //next state
                    states = state_Sub;
                    counter = counter + 5'b00001;
                end else if (Overflow && counter == 5'b00001) begin
                    //Erro de overflow so deve ser analisado apos o calculo
                    states = state_Overflow;
                    counter = 5'b00000;
                end else if (counter == 5'b00001) begin
                    RegDst    =   2'b11; ////
                    RegSrc    =   3'b010; ////
                    EPC_Load            =   1'b0;
                    MDR_Load            =   1'b0;
                    IRWrite             =   1'b0;
                    writeHL            =   1'b0;
                    A_Load              =   1'b0;
                    B_Load              =   1'b0;
                    ALUOut_Load         =   1'b0;
                    MemWR           =   1'b0;
                    IRWrite              =   1'b1; ////
                    PCWrite             =   1'b0;
                    PCWriteCond               =   1'b0;
                    FlagOption               =   1'b0;
                    BranchOption               =   1'b0;
                    
                    MultInit            =   1'b0;
                    DivInit             =   1'b0;

                    //next state
                    states = state_Fetch;
                    counter = 5'b00000;
                end
            end

            //BREAK
            state_Break: begin
                if (counter == 5'b00000) begin
                    ALUSrcA            =   2'b00; ////
                    ALUSrcB            =   3'b001; ////
                    PCSource              =   2'b01; ////
                    ALU                 =   3'b010; ////
                    EPC_Load            =   1'b0;
                    MDR_Load            =   1'b0;
                    IRWrite             =   1'b0;
                    writeHL            =   1'b0;
                    A_Load              =   1'b0;
                    B_Load              =   1'b0;
                    ALUOut_Load         =   1'b0;
                    MemWR           =   1'b0;
                    IRWrite              =   1'b0;
                    PCWrite             =   1'b1; ////
                    PCWriteCond               =   1'b0;
                    FlagOption               =   1'b0;
                    BranchOption               =   1'b0;
                    
                    MultInit            =   1'b0;
                    DivInit             =   1'b0;

                    //next state
                    states = state_Fetch;
                    counter = 5'b00000;
                end
            end

            //RTE
            state_RTE: begin
                if (counter == 5'b00000) begin
                    PCSource              =   2'b00; ////
                    EPC_Load            =   1'b0;
                    MDR_Load            =   1'b0;
                    IRWrite             =   1'b0;
                    writeHL            =   1'b0;
                    A_Load              =   1'b0;
                    B_Load              =   1'b0;
                    ALUOut_Load         =   1'b0;
                    MemWR           =   1'b0;
                    IRWrite              =   1'b0;
                    PCWrite             =   1'b1; ////
                    PCWriteCond               =   1'b0;
                    FlagOption               =   1'b0;
                    BranchOption               =   1'b0;
                    
                    MultInit            =   1'b0;
                    DivInit             =   1'b0;

                    //next state
                    states = state_Fetch;
                    counter = 5'b00000;
                end
            end

            //ADDI
            state_Addi: begin
                if (counter == 5'b00000) begin
                    ALUSrcA            =   2'b01; ////
                    ALUSrcB            =   3'b010; ////
                    ALU                 =   3'b001; ////
                    EPC_Load            =   1'b0;
                    MDR_Load            =   1'b0;
                    IRWrite             =   1'b0;
                    writeHL            =   1'b0;
                    A_Load              =   1'b0;
                    B_Load              =   1'b0;
                    ALUOut_Load         =   1'b1; ////
                    MemWR           =   1'b0;
                    IRWrite              =   1'b0;
                    PCWrite             =   1'b0;
                    PCWriteCond               =   1'b0;
                    FlagOption               =   1'b0;
                    BranchOption               =   1'b0;
                    
                    MultInit            =   1'b0;
                    DivInit             =   1'b0;

                    //next state
                    states = state_Addi;
                    counter = counter + 5'b00001;
                end else if (Overflow && counter == 5'b00001) begin
                    //Erro de overflow so deve ser analisado apos o calculo
                    states = state_Overflow;
                    counter = 5'b00000;
                end else if (counter == 5'b00001) begin
                    RegDst    =   2'b00; ////
                    RegSrc    =   3'b010; ////
                    EPC_Load            =   1'b0;
                    MDR_Load            =   1'b0;
                    IRWrite             =   1'b0;
                    writeHL            =   1'b0;
                    A_Load              =   1'b0;
                    B_Load              =   1'b0;
                    ALUOut_Load         =   1'b0;
                    MemWR           =   1'b0;
                    IRWrite              =   1'b1; ////
                    PCWrite             =   1'b0;
                    PCWriteCond               =   1'b0;
                    FlagOption               =   1'b0;
                    BranchOption               =   1'b0;
                    
                    MultInit            =   1'b0;
                    DivInit             =   1'b0;
                    //next state
                    states = state_Fetch;
                    counter = 5'b00000;
                end
            end

            //ADDIU
            state_Addiu: begin
                if (counter == 5'b00000) begin
                    ALUSrcA            =   2'b01; ////
                    ALUSrcB            =   3'b010; ////
                    ALU                 =   3'b001; ////
                    EPC_Load            =   1'b0;
                    MDR_Load            =   1'b0;
                    IRWrite             =   1'b0;
                    writeHL            =   1'b0;
                    A_Load              =   1'b0;
                    B_Load              =   1'b0;
                    ALUOut_Load         =   1'b1; ////
                    MemWR           =   1'b0;
                    IRWrite              =   1'b0;
                    PCWrite             =   1'b0;
                    PCWriteCond               =   1'b0;
                    FlagOption               =   1'b0;
                    BranchOption               =   1'b0;
                    
                    MultInit            =   1'b0;
                    DivInit             =   1'b0;

                    //next state
                    states = state_Addiu;
                    counter = counter + 5'b00001;
                end else if (counter == 5'b00001) begin
                    RegDst    =   2'b00; ////
                    RegSrc    =   3'b010; ////
                    EPC_Load            =   1'b0;
                    MDR_Load            =   1'b0;
                    IRWrite             =   1'b0;
                    writeHL            =   1'b0;
                    A_Load              =   1'b0;
                    B_Load              =   1'b0;
                    ALUOut_Load         =   1'b0;
                    MemWR           =   1'b0;
                    IRWrite              =   1'b1; ////
                    PCWrite             =   1'b0;
                    PCWriteCond               =   1'b0;
                    FlagOption               =   1'b0;
                    BranchOption               =   1'b0;
                    
                    MultInit            =   1'b0;
                    DivInit             =   1'b0;

                    //next state
                    states = state_Fetch;
                    counter = 5'b00000;
                end
            end

            //BEQ
            state_Beq: begin
                if (counter == 5'b00000) begin
                    ALUSrcA            =   2'b01; ////
                    ALUSrcB            =   3'b000; ////
                    PCSource              =   2'b10; ////
                    ALU                 =   3'b010; ////
                    EPC_Load            =   1'b0;
                    MDR_Load            =   1'b0;
                    IRWrite             =   1'b0;
                    writeHL            =   1'b0;
                    A_Load              =   1'b0;
                    B_Load              =   1'b0;
                    ALUOut_Load         =   1'b0;
                    MemWR           =   1'b0;
                    IRWrite              =   1'b0;
                    PCWrite             =   1'b0;
                    PCWriteCond               =   1'b1; ////
                    FlagOption               =   1'b0;
                    BranchOption               =   1'b0;
                    
                    MultInit            =   1'b0;
                    DivInit             =   1'b0;

                    //next state
                    states = state_Fetch;
                    counter = 5'b00000;
                end
            end

            //BNE
            state_Bne: begin
                if (counter == 5'b00000) begin
                    ALUSrcA            =   2'b01; ////
                    ALUSrcB            =   3'b000; ////
                    PCSource              =   2'b10; ////
                    ALU                 =   3'b010; ////
                    EPC_Load            =   1'b0;
                    MDR_Load            =   1'b0;
                    IRWrite             =   1'b0;
                    writeHL            =   1'b0;
                    A_Load              =   1'b0;
                    B_Load              =   1'b0;
                    ALUOut_Load         =   1'b0;
                    MemWR           =   1'b0;
                    IRWrite              =   1'b0;
                    PCWrite             =   1'b0;
                    PCWriteCond               =   1'b0;
                    FlagOption               =   1'b1; ////
                    BranchOption               =   1'b0;
                    
                    MultInit            =   1'b0;
                    DivInit             =   1'b0;

                    //next state
                    states = state_Fetch;
                    counter = 5'b00000;
                end
            end

            //BLE
            state_Ble: begin
                if (counter == 5'b00000) begin
                    ALUSrcA            =   2'b01; ////
                    ALUSrcB            =   3'b000; ////
                    PCSource              =   2'b10; ////
                    ALU                 =   3'b111; ////
                    EPC_Load            =   1'b0;
                    MDR_Load            =   1'b0;
                    IRWrite             =   1'b0;
                    writeHL            =   1'b0;
                    A_Load              =   1'b0;
                    B_Load              =   1'b0;
                    ALUOut_Load         =   1'b0;
                    MemWR           =   1'b0;
                    IRWrite              =   1'b0;
                    PCWrite             =   1'b0;
                    PCWriteCond               =   1'b0;
                    FlagOption               =   1'b0;
                    BranchOption               =   1'b1; ////
                    
                    MultInit            =   1'b0;
                    DivInit             =   1'b0;

                    //next state
                    states = state_Fetch;
                    counter = 5'b00000;
                end
            end
            

            //BGT
            state_Bgt: begin
                if (counter == 5'b00000) begin
                    ALUSrcA            =   2'b01; ////
                    ALUSrcB            =   3'b000; ////
                    PCSource              =   2'b10; ////
                    ALU                 =   3'b111; ////
                    EPC_Load            =   1'b0;
                    MDR_Load            =   1'b0;
                    IRWrite             =   1'b0;
                    writeHL            =   1'b0;
                    A_Load              =   1'b0;
                    B_Load              =   1'b0;
                    ALUOut_Load         =   1'b0;
                    MemWR           =   1'b0;
                    IRWrite              =   1'b0;
                    PCWrite             =   1'b0;
                    PCWriteCond               =   1'b0;
                    FlagOption               =   1'b0;
                    BranchOption               =   1'b0;
                    
                    MultInit            =   1'b0;
                    DivInit             =   1'b0;

                    //next state
                    states = state_Fetch;
                    counter = 5'b00000;
                end
            end

            //LB
            state_Lb: begin
                if (counter == 5'b00000) begin
                    ALUSrcA            =   2'b01; ////
                    ALUSrcB            =   3'b010; ////
                    ALU                 =   3'b001; ////
                    EPC_Load            =   1'b0;
                    MDR_Load            =   1'b0;
                    IRWrite             =   1'b0;
                    writeHL            =   1'b0;
                    A_Load              =   1'b0;
                    B_Load              =   1'b0;
                    ALUOut_Load         =   1'b1; ////
                    MemWR           =   1'b0;
                    IRWrite              =   1'b0;
                    PCWrite             =   1'b0;
                    PCWriteCond               =   1'b0;
                    FlagOption               =   1'b0;
                    BranchOption               =   1'b0;
                    
                    MultInit            =   1'b0;
                    DivInit             =   1'b0;

                    //next state
                    states = state_Lb;
                    counter = counter + 5'b00001;
                end else if (Overflow && counter == 5'b00001) begin
                    //Erro de overflow so deve ser analisado apos o calculo
                    states = state_Overflow;
                    counter = 5'b00000;
                end else if (counter == 5'b00001 || counter == 5'b00010 || counter == 5'b00011) begin
                    AddressCtrl         =   3'b001; ////
                    EPC_Load            =   1'b0;
                    MDR_Load            =   1'b0;
                    IRWrite             =   1'b0;
                    writeHL            =   1'b0;
                    A_Load              =   1'b0;
                    B_Load              =   1'b0;
                    ALUOut_Load         =   1'b0;
                    MemWR           =   1'b0;
                    IRWrite              =   1'b0;
                    PCWrite             =   1'b0;
                    PCWriteCond               =   1'b0;
                    FlagOption               =   1'b0;
                    BranchOption               =   1'b0;
                    
                    MultInit            =   1'b0;
                    DivInit             =   1'b0;

                    //next state
                    states = state_Lb;
                    counter = counter + 5'b00001;
                end else if (counter == 5'b00100) begin
                    EPC_Load            =   1'b0;
                    MDR_Load            =   1'b1; ////
                    IRWrite             =   1'b0;
                    writeHL            =   1'b0;
                    A_Load              =   1'b0;
                    B_Load              =   1'b0;
                    ALUOut_Load         =   1'b0;
                    MemWR           =   1'b0;
                    IRWrite              =   1'b0;
                    PCWrite             =   1'b0;
                    PCWriteCond               =   1'b0;
                    FlagOption               =   1'b0;
                    BranchOption               =   1'b0;
                    
                    MultInit            =   1'b0;
                    DivInit             =   1'b0;

                    //next state
                    states = state_Lb;
                    counter = counter + 5'b00001;
                end else if (counter == 5'b00101) begin
                    LStoreSizeCtrl           =   2'b00; ////
                    RegDst    =   2'b00; ////
                    RegSrc    =   3'b001; ////
                    EPC_Load            =   1'b0;
                    MDR_Load            =   1'b0;
                    IRWrite             =   1'b0;
                    writeHL            =   1'b0;
                    A_Load              =   1'b0;
                    B_Load              =   1'b0;
                    ALUOut_Load         =   1'b0;
                    MemWR           =   1'b0;
                    IRWrite              =   1'b1; ////
                    PCWrite             =   1'b0;
                    PCWriteCond               =   1'b0;
                    FlagOption               =   1'b0;
                    BranchOption               =   1'b0;
                    
                    MultInit            =   1'b0;
                    DivInit             =   1'b0;

                    //next state
                    states = state_Fetch;
                    counter = 5'b00000;
                end
            end

            //LH
            state_Lh: begin
                if (counter == 5'b00000) begin
                    ALUSrcA            =   2'b01; ////
                    ALUSrcB            =   3'b010; ////
                    ALU                 =   3'b001; ////
                    EPC_Load            =   1'b0;
                    MDR_Load            =   1'b0;
                    IRWrite             =   1'b0;
                    writeHL            =   1'b0;
                    A_Load              =   1'b0;
                    B_Load              =   1'b0;
                    ALUOut_Load         =   1'b1; ////
                    MemWR           =   1'b0;
                    IRWrite              =   1'b0;
                    PCWrite             =   1'b0;
                    PCWriteCond               =   1'b0;
                    FlagOption               =   1'b0;
                    BranchOption               =   1'b0;
                    
                    MultInit            =   1'b0;
                    DivInit             =   1'b0;

                    //next state
                    states = state_Lh;
                    counter = counter + 5'b00001;
                end else if (Overflow && counter == 5'b00001) begin
                    //Erro de overflow so deve ser analisado apos o calculo
                    states = state_Overflow;
                    counter = 5'b00000;
                end else if (counter == 5'b00001 || counter == 5'b00010 || counter == 5'b00011) begin
                    AddressCtrl         =   3'b001; ////
                    EPC_Load            =   1'b0;
                    MDR_Load            =   1'b0;
                    IRWrite             =   1'b0;
                    writeHL            =   1'b0;
                    A_Load              =   1'b0;
                    B_Load              =   1'b0;
                    ALUOut_Load         =   1'b0;
                    MemWR           =   1'b0;
                    IRWrite              =   1'b0;
                    PCWrite             =   1'b0;
                    PCWriteCond               =   1'b0;
                    FlagOption               =   1'b0;
                    BranchOption               =   1'b0;
                    
                    MultInit            =   1'b0;
                    DivInit             =   1'b0;

                    //next state
                    states = state_Lh;
                    counter = counter + 5'b00001;
                end else if (counter == 5'b00100) begin
                    EPC_Load            =   1'b0;
                    MDR_Load            =   1'b1; ////
                    IRWrite             =   1'b0;
                    writeHL            =   1'b0;
                    A_Load              =   1'b0;
                    B_Load              =   1'b0;
                    ALUOut_Load         =   1'b0;
                    MemWR           =   1'b0;
                    IRWrite              =   1'b0;
                    PCWrite             =   1'b0;
                    PCWriteCond               =   1'b0;
                    FlagOption               =   1'b0;
                    BranchOption               =   1'b0;
                    
                    MultInit            =   1'b0;
                    DivInit             =   1'b0;

                    //next state
                    states = state_Lh;
                    counter = counter + 5'b00001;
                end else if (counter == 5'b00101) begin
                    LStoreSizeCtrl           =   2'b01; ////
                    RegDst    =   2'b00; ////
                    RegSrc    =   3'b001; ////
                    EPC_Load            =   1'b0;
                    MDR_Load            =   1'b0;
                    IRWrite             =   1'b0;
                    writeHL            =   1'b0;
                    A_Load              =   1'b0;
                    B_Load              =   1'b0;
                    ALUOut_Load         =   1'b0;
                    MemWR           =   1'b0;
                    IRWrite              =   1'b1; ////
                    PCWrite             =   1'b0;
                    PCWriteCond               =   1'b0;
                    FlagOption               =   1'b0;
                    BranchOption               =   1'b0;
                    
                    MultInit            =   1'b0;
                    DivInit             =   1'b0;

                    //next state
                    states = state_Fetch;
                    counter = 5'b00000;
                end
            end

            //LUI
            state_Lui: begin
                if (counter == 5'b00000) begin
                    RegDst    =   2'b00; ////
                    RegSrc    =   3'b111; ////
                    EPC_Load            =   1'b0;
                    MDR_Load            =   1'b0;
                    IRWrite             =   1'b0;
                    writeHL            =   1'b0;
                    A_Load              =   1'b0;
                    B_Load              =   1'b0;
                    ALUOut_Load         =   1'b0;
                    MemWR           =   1'b0;
                    IRWrite              =   1'b1; ////
                    PCWrite             =   1'b0;
                    PCWriteCond               =   1'b0;
                    FlagOption               =   1'b0;
                    BranchOption               =   1'b0;
                    
                    MultInit            =   1'b0;
                    DivInit             =   1'b0;

                    //next state
                    states = state_Fetch;
                    counter = 5'b00000;
                end
            end

            //LW
            state_Lw: begin
                if (counter == 5'b00000) begin
                    ALUSrcA            =   2'b01; ////
                    ALUSrcB            =   3'b010; ////
                    ALU                 =   3'b001; ////
                    EPC_Load            =   1'b0;
                    MDR_Load            =   1'b0;
                    IRWrite             =   1'b0;
                    writeHL            =   1'b0;
                    A_Load              =   1'b0;
                    B_Load              =   1'b0;
                    ALUOut_Load         =   1'b1; ////
                    MemWR           =   1'b0;
                    IRWrite              =   1'b0;
                    PCWrite             =   1'b0;
                    PCWriteCond               =   1'b0;
                    FlagOption               =   1'b0;
                    BranchOption               =   1'b0;
                    
                    MultInit            =   1'b0;
                    DivInit             =   1'b0;

                    //next state
                    states = state_Lw;
                    counter = counter + 5'b00001;
                end else if (Overflow && counter == 5'b00001) begin
                    //Erro de overflow so deve ser analisado apos o calculo
                    states = state_Overflow;
                    counter = 5'b00000;
                end else if (counter == 5'b00001 || counter == 5'b00010 || counter == 5'b00011) begin
                    AddressCtrl         =   3'b001; ////
                    EPC_Load            =   1'b0;
                    MDR_Load            =   1'b0;
                    IRWrite             =   1'b0;
                    writeHL            =   1'b0;
                    A_Load              =   1'b0;
                    B_Load              =   1'b0;
                    ALUOut_Load         =   1'b0;
                    MemWR           =   1'b0;
                    IRWrite              =   1'b0;
                    PCWrite             =   1'b0;
                    PCWriteCond               =   1'b0;
                    FlagOption               =   1'b0;
                    BranchOption               =   1'b0;
                    
                    MultInit            =   1'b0;
                    DivInit             =   1'b0;

                    //next state
                    states = state_Lw;
                    counter = counter + 5'b00001;
                end else if (counter == 5'b00100) begin
                    EPC_Load            =   1'b0;
                    MDR_Load            =   1'b1; ////
                    IRWrite             =   1'b0;
                    writeHL            =   1'b0;
                    A_Load              =   1'b0;
                    B_Load              =   1'b0;
                    ALUOut_Load         =   1'b0;
                    MemWR           =   1'b0;
                    IRWrite              =   1'b0;
                    PCWrite             =   1'b0;
                    PCWriteCond               =   1'b0;
                    FlagOption               =   1'b0;
                    BranchOption               =   1'b0;
                    
                    MultInit            =   1'b0;
                    DivInit             =   1'b0;

                    //next state
                    states = state_Lw;
                    counter = counter + 5'b00001;
                end else if (counter == 5'b00101) begin
                    LStoreSizeCtrl           =   2'b10; ////
                    RegDst    =   2'b00; ////
                    RegSrc    =   3'b001; ////
                    EPC_Load            =   1'b0;
                    MDR_Load            =   1'b0;
                    IRWrite             =   1'b0;
                    writeHL            =   1'b0;
                    A_Load              =   1'b0;
                    B_Load              =   1'b0;
                    ALUOut_Load         =   1'b0;
                    MemWR           =   1'b0;
                    IRWrite              =   1'b1; ////
                    PCWrite             =   1'b0;
                    PCWriteCond               =   1'b0;
                    FlagOption               =   1'b0;
                    BranchOption               =   1'b0;
                    
                    MultInit            =   1'b0;
                    DivInit             =   1'b0;

                    //next state
                    states = state_Fetch;
                    counter = 5'b00000;
                end
            end

            //SB
            state_Sb: begin
                if (counter == 5'b00000) begin
                    ALUSrcA            =   2'b01; ////
                    ALUSrcB            =   3'b010; ////
                    ALU                 =   3'b001; ////
                    EPC_Load            =   1'b0;
                    MDR_Load            =   1'b0;
                    IRWrite             =   1'b0;
                    writeHL            =   1'b0;
                    A_Load              =   1'b0;
                    B_Load              =   1'b0;
                    ALUOut_Load         =   1'b1; ////
                    MemWR           =   1'b0;
                    IRWrite              =   1'b0;
                    PCWrite             =   1'b0;
                    PCWriteCond               =   1'b0;
                    FlagOption               =   1'b0;
                    BranchOption               =   1'b0;
                    
                    MultInit            =   1'b0;
                    DivInit             =   1'b0;

                    //next state
                    states = state_Sb;
                    counter = counter + 5'b00001;
                end else if (Overflow && counter == 5'b00001) begin
                    //Erro de overflow so deve ser analisado apos o calculo
                    states = state_Overflow;
                    counter = 5'b00000;
                end else if (counter == 5'b00001 || counter == 5'b00010 || counter == 5'b00011) begin
                    AddressCtrl         =   3'b001; ////
                    EPC_Load            =   1'b0;
                    MDR_Load            =   1'b0;
                    IRWrite             =   1'b0;
                    writeHL            =   1'b0;
                    A_Load              =   1'b0;
                    B_Load              =   1'b0;
                    ALUOut_Load         =   1'b0;
                    MemWR           =   1'b0;
                    IRWrite              =   1'b0;
                    PCWrite             =   1'b0;
                    PCWriteCond               =   1'b0;
                    FlagOption               =   1'b0;
                    BranchOption               =   1'b0;
                    
                    MultInit            =   1'b0;
                    DivInit             =   1'b0;

                    //next state
                    states = state_Sb;
                    counter = counter + 5'b00001;
                end else if (counter == 5'b00100) begin
                    EPC_Load            =   1'b0;
                    MDR_Load            =   1'b1; ////
                    IRWrite             =   1'b0;
                    writeHL            =   1'b0;
                    A_Load              =   1'b0;
                    B_Load              =   1'b0;
                    ALUOut_Load         =   1'b0;
                    MemWR           =   1'b0;
                    IRWrite              =   1'b0;
                    PCWrite             =   1'b0;
                    PCWriteCond               =   1'b0;
                    FlagOption               =   1'b0;
                    BranchOption               =   1'b0;
                    
                    MultInit            =   1'b0;
                    DivInit             =   1'b0;

                    //next state
                    states = state_Sb;
                    counter = counter + 5'b00001;
                end else if (counter == 5'b00101) begin
                    AddressCtrl         =   3'b001; ////
                    WriteMemoSrc       =   1'b1; ////
                    StoreSizeCtrl          =   1'b0; ////
                    EPC_Load            =   1'b0;
                    MDR_Load            =   1'b0;
                    IRWrite             =   1'b0;
                    writeHL            =   1'b0;
                    A_Load              =   1'b0;
                    B_Load              =   1'b0;
                    ALUOut_Load         =   1'b0;
                    MemWR           =   1'b1; ////
                    IRWrite              =   1'b0;
                    PCWrite             =   1'b0;
                    PCWriteCond               =   1'b0;
                    FlagOption               =   1'b0;
                    BranchOption               =   1'b0;
                    
                    MultInit            =   1'b0;
                    DivInit             =   1'b0;

                    //next state
                    states = state_Fetch;
                    counter = 5'b00000;
                end
            end

            //SH
            state_Sh: begin
                if (counter == 5'b00000) begin
                    ALUSrcA            =   2'b01; ////
                    ALUSrcB            =   3'b010; ////
                    ALU                 =   3'b001; ////
                    EPC_Load            =   1'b0;
                    MDR_Load            =   1'b0;
                    IRWrite             =   1'b0;
                    writeHL            =   1'b0;
                    A_Load              =   1'b0;
                    B_Load              =   1'b0;
                    ALUOut_Load         =   1'b1; ////
                    MemWR           =   1'b0;
                    IRWrite              =   1'b0;
                    PCWrite             =   1'b0;
                    PCWriteCond               =   1'b0;
                    FlagOption               =   1'b0;
                    BranchOption               =   1'b0;
                    
                    MultInit            =   1'b0;
                    DivInit             =   1'b0;

                    //next state
                    states = state_Sh;
                    counter = counter + 5'b00001;
                end else if (Overflow && counter == 5'b00001) begin
                    //Erro de overflow so deve ser analisado apos o calculo
                    states = state_Overflow;
                    counter = 5'b00000;
                end else if (counter == 5'b00001 || counter == 5'b00010 || counter == 5'b00011) begin
                    AddressCtrl         =   3'b001; ////
                    EPC_Load            =   1'b0;
                    MDR_Load            =   1'b0;
                    IRWrite             =   1'b0;
                    writeHL            =   1'b0;
                    A_Load              =   1'b0;
                    B_Load              =   1'b0;
                    ALUOut_Load         =   1'b0;
                    MemWR           =   1'b0;
                    IRWrite              =   1'b0;
                    PCWrite             =   1'b0;
                    PCWriteCond               =   1'b0;
                    FlagOption               =   1'b0;
                    BranchOption               =   1'b0;
                    
                    MultInit            =   1'b0;
                    DivInit             =   1'b0;

                    //next state
                    states = state_Sh;
                    counter = counter + 5'b00001;
                end else if (counter == 5'b00100) begin
                    EPC_Load            =   1'b0;
                    MDR_Load            =   1'b1; ////
                    IRWrite             =   1'b0;
                    writeHL            =   1'b0;
                    A_Load              =   1'b0;
                    B_Load              =   1'b0;
                    ALUOut_Load         =   1'b0;
                    MemWR           =   1'b0;
                    IRWrite              =   1'b0;
                    PCWrite             =   1'b0;
                    PCWriteCond               =   1'b0;
                    FlagOption               =   1'b0;
                    BranchOption               =   1'b0;
                    
                    MultInit            =   1'b0;
                    DivInit             =   1'b0;

                    //next state
                    states = state_Sh;
                    counter = counter + 5'b00001;
                end else if (counter == 5'b00101) begin
                    AddressCtrl         =   3'b001; ////
                    WriteMemoSrc       =   1'b1; ////
                    StoreSizeCtrl          =   1'b1; ////
                    EPC_Load            =   1'b0;
                    MDR_Load            =   1'b0;
                    IRWrite             =   1'b0;
                    writeHL            =   1'b0;
                    A_Load              =   1'b0;
                    B_Load              =   1'b0;
                    ALUOut_Load         =   1'b0;
                    MemWR           =   1'b1; ////
                    IRWrite              =   1'b0;
                    PCWrite             =   1'b0;
                    PCWriteCond               =   1'b0;
                    FlagOption               =   1'b0;
                    BranchOption               =   1'b0;
                    
                    MultInit            =   1'b0;
                    DivInit             =   1'b0;

                    //next state
                    states = state_Fetch;
                    counter = 5'b00000;
                end
            end

            //SLTI
            state_Slti: begin
                if (counter == 5'b00000) begin
                    ALUSrcA            =   2'b01; ////
                    ALUSrcB            =   3'b010; ////
                    ALU                 =   3'b111; ////
                    EPC_Load            =   1'b0;
                    MDR_Load            =   1'b0;
                    IRWrite             =   1'b0;
                    writeHL            =   1'b0;
                    A_Load              =   1'b0;
                    B_Load              =   1'b0;
                    ALUOut_Load         =   1'b0;
                    MemWR           =   1'b0;
                    IRWrite              =   1'b0;
                    PCWrite             =   1'b0;
                    PCWriteCond               =   1'b0;
                    FlagOption               =   1'b0;
                    BranchOption               =   1'b0;
                    
                    MultInit            =   1'b0;
                    DivInit             =   1'b0;

                    //next state
                    states = state_Slti;
                    counter = counter + 5'b00001;
                end else if (counter == 5'b00001) begin
                    RegDst    =   2'b00; ////
                    RegSrc    =   3'b110; ////
                    EPC_Load            =   1'b0;
                    MDR_Load            =   1'b0;
                    IRWrite             =   1'b0;
                    writeHL            =   1'b0;
                    A_Load              =   1'b0;
                    B_Load              =   1'b0;
                    ALUOut_Load         =   1'b0;
                    MemWR           =   1'b0;
                    IRWrite              =   1'b1; ////
                    PCWrite             =   1'b0;
                    PCWriteCond               =   1'b0;
                    FlagOption               =   1'b0;
                    BranchOption               =   1'b0;
                    
                    MultInit            =   1'b0;
                    DivInit             =   1'b0;

                    //next state
                    states = state_Fetch;
                    counter = 5'b00000;
                end
            end

            //SW
            state_Sw: begin
                if (counter == 5'b00000) begin
                    ALUSrcA            =   2'b01; ////
                    ALUSrcB            =   3'b010; ////
                    ALU                 =   3'b001; ////
                    EPC_Load            =   1'b0;
                    MDR_Load            =   1'b0;
                    IRWrite             =   1'b0;
                    writeHL            =   1'b0;
                    A_Load              =   1'b0;
                    B_Load              =   1'b0;
                    ALUOut_Load         =   1'b1; ////
                    MemWR           =   1'b0;
                    IRWrite              =   1'b0;
                    PCWrite             =   1'b0;
                    PCWriteCond               =   1'b0;
                    FlagOption               =   1'b0;
                    BranchOption               =   1'b0;
                    
                    MultInit            =   1'b0;
                    DivInit             =   1'b0;

                    //next state
                    states = state_Sw;
                    counter = counter + 5'b00001;
                end else if (Overflow && counter == 5'b00001) begin
                    //Erro de overflow so deve ser analisado apos o calculo
                    states = state_Overflow;
                    counter = 5'b00000;
                end else if (counter == 5'b00001) begin
                    AddressCtrl         =   3'b001; ////
                    WriteMemoSrc       =   1'b0; ////                    
                    EPC_Load            =   1'b0;
                    MDR_Load            =   1'b0;
                    IRWrite             =   1'b0;
                    writeHL            =   1'b0;
                    A_Load              =   1'b0;
                    B_Load              =   1'b0;
                    ALUOut_Load         =   1'b0;
                    MemWR           =   1'b1; ////
                    IRWrite              =   1'b0;
                    PCWrite             =   1'b0;
                    PCWriteCond               =   1'b0;
                    FlagOption               =   1'b0;
                    BranchOption               =   1'b0;
                    
                    MultInit            =   1'b0;
                    DivInit             =   1'b0;

                    //next state
                    states = state_Fetch;
                    counter = 5'b00000;
                end
            end

            //J
            state_J: begin
                if (counter == 5'b00000) begin
                    PCSource              =   2'b11; ////
                    EPC_Load            =   1'b0;
                    MDR_Load            =   1'b0;
                    IRWrite             =   1'b0; 
                    writeHL            =   1'b0;
                    A_Load              =   1'b0;
                    B_Load              =   1'b0;
                    ALUOut_Load         =   1'b0;
                    MemWR           =   1'b0;
                    IRWrite              =   1'b0;
                    PCWrite             =   1'b1; ////
                    PCWriteCond               =   1'b0;
                    FlagOption               =   1'b0;
                    BranchOption               =   1'b0;
                    
                    MultInit            =   1'b0;
                    DivInit             =   1'b0;

                    //next state
                    states = state_Fetch;
                    counter = 5'b00000;
                end
            end
            
            //JAL
            state_Jal: begin
                if (counter == 5'b00000) begin
                    ALUSrcA            =   2'b00; ////
                    ALUSrcB            =   3'b000; ////
                    ALU                 =   3'b000;  ////
                    EPC_Load            =   1'b0;
                    MDR_Load            =   1'b0;
                    IRWrite             =   1'b0; 
                    writeHL            =   1'b0;
                    A_Load              =   1'b0;
                    B_Load              =   1'b0;
                    ALUOut_Load         =   1'b1;  ////
                    MemWR           =   1'b0;
                    IRWrite              =   1'b0;
                    PCWrite             =   1'b0;
                    PCWriteCond               =   1'b0;
                    FlagOption               =   1'b0;
                    BranchOption               =   1'b0;
                    
                    MultInit            =   1'b0;
                    DivInit             =   1'b0;

                    //next state
                    states = state_Jal;
                    counter = counter + 5'b00001;
                end else if (counter == 5'b00001) begin
                    PCSource              =   2'b11; ////
                    RegSrc    =   3'b010; ////
                    RegDst    =   2'b10; ////
                    EPC_Load            =   1'b0;
                    MDR_Load            =   1'b0;
                    IRWrite             =   1'b0; 
                    writeHL            =   1'b0;
                    A_Load              =   1'b0;
                    B_Load              =   1'b0;
                    ALUOut_Load         =   1'b0;
                    MemWR           =   1'b0;
                    IRWrite              =   1'b1; ////
                    PCWrite             =   1'b1; ////
                    PCWriteCond               =   1'b0;
                    FlagOption               =   1'b0;
                    BranchOption               =   1'b0;
                    
                    MultInit            =   1'b0;
                    DivInit             =   1'b0;

                    //next state
                    states = state_Fetch;
                    counter = 5'b00000;
                end
            end
        endcase

    end
    
end

endmodule