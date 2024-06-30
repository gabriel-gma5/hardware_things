module SizeLoad (
    input [31:0] data_in_MDR, 
    input [1:0] LSizeCtrl,
    output reg [31:0] data_out
);
/* 
    O LSizeCtrl é um sinal de 2 bits que determina como os dados de entrada data_in_MDR devem ser manipulados para gerar a saída data_out.
    
    Seleção do LSizeCtrl:
    LSizeCtrl == 2'b01 (binário 01, HALFWORD)
        A saída data_out é definida como {16'b0, data_in_MDR[15:0]}. 
        Isso significa que os 16 bits mais significativos de data_out são preenchidos com zeros, e os 16 bits menos significativos são copiados de data_in_MDR[15:0].
    LSizeCtrl == 2'b10 (binário 10, BYTE)
        A saída data_out é definida como {24'b0, data_in_MDR[7:0]}.
        Nesse caso, os 24 bits mais significativos de data_out são preenchidos com zeros, e os 8 bits menos significativos são copiados de data_in_MDR[7:0].
    Se nenhuma das condições acima for atendida (ou seja, o valor de LSizeCtrl não é 01 nem 10), a saída data_out é definida como data_in_MDR.
        Isso significa que data_out é uma cópia direta de data_in_MDR.
*/

    always @(*) begin
        case(LSizeCtrl)
            2'b01: data_out = {16'b0, data_in_MDR[15:0]};
            2'b10: data_out = {24'b0, data_in_MDR[7:0]};
            default: data_out = data_in_MDR;
        endcase
    end
    
endmodule