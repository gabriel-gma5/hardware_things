addi $2, $0, 10    # $2 = 10
addi $3, $0, 2     # $3 = 2
addi $4, $0, 3     # $4 = 3
addi $5, $0, -3    # $5 = -3
addi $6, $0, -10   # $6 = -10
div $2, $3         # hi = 0, lo = 5
div $2, $4         # hi = 1, lo = 3
div $2, $5         # hi = 1, lo = -3
div $6, $5         # hi = -1, lo = 3
mfhi $7            # $7 = -1
mflo $8            # $8 = 3
div $2, $0         # divisao por zero