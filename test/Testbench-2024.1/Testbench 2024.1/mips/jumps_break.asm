addi $2, $2, 1	# $2 = 1
j first_jump
addi $2, $2, 2	# não executa

first_jump:
jal second_jump		# pula para depois do break
addi $2, $2, 5	# $2 = 9
break		# para a execução

second_jump:
addi $2, $2, 3	# $2 = 4
jr $31		# volta para depois do jal