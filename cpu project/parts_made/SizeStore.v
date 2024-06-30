module SizeStore (
    input [31:0] data_in_MDR, 
    input [31:0] data_in_B, 
    input [1:0] SSizeCtrl,
    output reg [31:0] data_out
);

/*
 O SizeCtrl é um sinal de 2 bits que determina como os dados de entrada data_in_MDR devem ser manipulados para gerar a saída data_out.
    
    Seleção do SizeCtrl:
    SizeCtrl == 2'b01 (binário 01, HALFWORD)
        A saída data_out é definida como {data_in_MDR[31:16], data_in_B[15:0]}. 
        Isso significa que os 16 bits mais significativos de data_out são preenchidos os 16 mais significativos do MDR, e os 16 bits menos significativos são copiados de data_in_B[15:0].
    SizeCtrl == 2'b10 (binário 10, BYTE)
        A saída data_out é definida como {data_in_MDR[31:8], data_in_B[7:0]}.
        Nesse caso, os 24 bits mais significativos de data_out são preenchidos os 24 mais significativos do MDR, e os 8 bits menos significativos são copiados de data_in_B[7:0].
    Se nenhuma das condições acima for atendida (ou seja, o valor de SizeCtrl não é 01 nem 10), a saída data_out é definida como data_in_B.
        Isso significa que data_out é uma cópia direta de data_in_B.
*/

    always @(*) begin
        case(SSizeCtrl)
            2'b01: data_out = {data_in_MDR[31:16], data_in_B[15:0]};
            2'b10: data_out = {data_in_MDR[31:8], data_in_B[7:0]};
            2'b11: data_out = data_in_MDR;
            default: data_out = data_in_B;
        endcase
    end
    
endmodule