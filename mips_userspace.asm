.text
.globl main

# SALTA PARA O IN�CIO DO C�DIGO DO USU�RIO
#####################################################
main:
        j MyMain

# ROTINA PARA TRATAMENTO DAS CHAMADAS DE INTERRUP��O
#####################################################
DesvioParaTratamentoDeInterrupcoes:
        subu $sp, $sp, 4
        sw $ra, 0($sp)
        la $k0, EnderecoSisCom
        lw $k0, 0($k0)
        sll $k0, $k0, 0x02
        la $k1, TabelaDeInterrupcoes
        addu $k0, $k0, $k1
        jalr $k0
        lw $ra, 0($sp)
        addiu $sp, $sp, 4
        # eret realiza a volta via o EPC do coprocessador 0
        mtc0 $ra,$14
        eret

# ENDERE�O DA TABELA DE ENDERE�AMENTO DE INTERRUP��ES
########################################################
TabelaDeInterrupcoes:
        j CPU_to_SisCom
        j SisCom_to_CPU

# ROTINAS PARA TRATAR AS INTERRUP��ES
#####################################
CPU_to_SisCom:
        subu $sp, $sp, 20
        sw $t0, 0($sp)
        sw $t3, 4($sp)
        sw $t4, 8($sp)
        sw $t6, 12($sp)
        sw $ra, 16($sp)
        
        la      $t2, StringMem
        la      $t0, EnderecoSisCom
envia:  lb      $t1, 0($t2)
        blez    $t1, segueE
        sw      $t1, 4($t0)
        addi    $t2, $t2, 1        
        j		envia				# jump to envia
        

segueE:  lw $ra, 16($sp)
        lw $t6, 12($sp)
        lw $t4, 8($sp)
        lw $t3, 4($sp)
        lw $t0, 0($sp)
        addiu $sp, $sp, 20
        jr $ra

#############################################
SisCom_to_CPU:
        subu $sp, $sp, 20
        sw $t0, 0($sp)
        sw $t3, 4($sp)
        sw $t4, 8($sp)
        sw $t6, 12($sp)
        sw $ra, 16($sp)
       
        la      $t2, EnderecoSisCom
recebe: lb      $t1, 8($t2)
        blez    $t1, segueR
        la      $t0, StringMem
        sw      $t1, 0($t0)
        addi    $t0, $t0, 1
        j		recebe			# jump to recebe        

segueR: lw $ra, 16($sp)
        lw $t6, 12($sp)
        lw $t4, 8($sp)
        lw $t3, 4($sp)
        lw $t0, 0($sp)
        addiu $sp, $sp, 20
        jr $ra

# IN�CIO DO PROGRAMA DO USU�RIO NO ENDERE�O
#############################################
MyMain:
        li $t0, 0
        li $t1, 0
        li $t2, 0
        jal ProcessamentoDoSisComInit
SaltoMyMain:
        addiu $t0, $t0, 1
        addu $t1, $t1, $t0
        jal ProcessamentoDoSisCom
        addu $t2, $t1, $t0
        j SaltoMyMain

# Funcao que simula a computacao
# registrador t7 guardar� o ciclo atual do SisCom
ProcessamentoDoSisComInit:
	lw $t7,  CiclosParaInterrupcaoSisCom
	jr $ra
ProcessamentoDoSisCom:
	subi $t7, $t7, 1
	blez $t7, InterrupcaoDeFato
	# senao, volte ao processamento normal
	jr $ra
	
# simulacao de recebimento de interrupcao
InterrupcaoDeFato:
	# esse processo deve ser feito em HARDWARE
	subi $sp, $sp, 4
	sw $ra, 0($sp)
	jal DesvioParaTratamentoDeInterrupcoes
	# reinicializa contador de ciclos
	jal ProcessamentoDoSisComInit
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	jr $ra
	
#################################################
# segmento de data comum
.data 0x10010000
CiclosParaInterrupcaoSisCom:	.word 20
StringMem:      .ascii  "Isto é um teste"

# ENDERE�O DO SISCOM
####################
# NOTE que o endereco verdadeiro para o hardware eh FFE00000
# mas para o simulador MARS utilizaremos o segmento de memory-mapped IO (FFFF0000)
# note que ao ler o endereco, o hardware ira responder, mas nesse teste o valor de
# respostas eh hard-coded (0)
.data 0xFFFF0000
EnderecoSisCom:			.word 0
