div $2, $2		# trata div. por zero
			# hi = 1

lui $3, 32767		# $3 = 2147418112
addi $3, $3, 32767	# $3 = 2147450879
addi $3, $3, 32767	# $3 = 2147483646
addi $3, $3, 2		# trata overflow
			# $3 = 1

null			# trata opcode inexistente

# tratamento divisao
addi $2, $0, 1		# $2 = 1
rte			# retorna pro div e executa normalmente

# tratamento overflow
addi $3, $0, -1		# $3 = -1
rte			# retorna pro addi e executa normalmente

# tratamento opcode
addi $4, $0, 1		# $4 = 1

# No final fica:
# $2 = 1
# $3 = 1
# $4 = 1