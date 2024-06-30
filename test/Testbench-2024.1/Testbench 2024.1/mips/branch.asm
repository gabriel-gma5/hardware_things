addi $2, $0, 2     # $2 = 2
addi $3, $0, 3     # $3 = 3

#TODOS OS BRANCHS PULAM
beq $2, $2, first_branch
addi $4, $4, 1000    # não executa
addi $0, $0, 0

first_branch:
bne $2, $3, second_branch
addi $4, $4, 100    # não executa
addi $0, $0, 0

second_branch:
ble $2, $3, third_branch
addi $4, $4, 10    # não executa
addi $0, $0, 0

third_branch:
bgt $3, $2, fourth_branch
addi $4, $4, 1    # não executa
addi $0, $0, 0

# $4 = 0

#NENHUM BRANCH PULA
fourth_branch:
beq $2, $3, fifth_branch
addi $5, $5, 1000    # $5 = 1000

fifth_branch:
bne $2, $2, sixth_branch
addi $5, $5, 100    # $5 = 1100

sixth_branch:
ble $3, $2, seventh_branch
addi $5, $5, 10    # $5 = 1110

seventh_branch:
bgt $2, $3, eighth_branch
addi $5, $5, 1    # $5 = 1111

eighth_branch: