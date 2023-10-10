
; 	Nome: Maximus Borges da Rosa	Número do cartão: 342337

;=====================================================================================
;
;			Trabalho de programação: Processador INTEL (80x86)
;
;=====================================================================================

.model		small
.stack

CR		equ		13
LF		equ		10

.data

; Linha de comando

	PSP					 db		128	dup(0)	; Cópia da cauda da linha de comando
	command_code		 db		10	dup(0) 	; Código de comando fornecido (em forma de string)
	flag_cmnd			 db		0
	flag_a				 db		0
	flag_t				 db		0
	flag_c				 db		0
	flag_g				 db		0
	flag_add			 db 	0
	num					 dw 	0
	flag_n				 db		0

	num_ascii			 db		"00000", 0	; número máximo de bases = 10000
	linha_ascii			 db		"0000", 0	; número máximo de linhas pra 10.000 bases = 1.630
	char_invalido		 db		0

	input_file_name		 db		13	dup(0)
	flag_f				 db		0
	output_file_name	 db		13	dup(0)
	flag_o				 db		0
	std_output_file_name db		"a.out", 0  ; Nome padrão do arquivo de saída

; Arquivos

	file_buffer			 db		0
	file_handle			 dw		0			; Handle do arquivo de entrada
	csv_file_handle		 dw		0			; Handle do arquivo de saída

; Mensagens

	msgErroOpen			   	db		"Erro na abertura do arquivo ", CR, LF, 0
	msgErroCreate		 	db		"Erro na criacao do arquivo.", CR, LF, 0
	msgErroRead			 	db		"Erro na leitura do arquivo.", CR, LF, 0
	msgCharInvalidoPt1	 	db		"Erro: Caractere invalido ", 0
	msgCharInvalidoPt2	 	db		"encontrado na linha ", 0
	msgArquivoMtGrande	 	db 		"Erro: O arquivo possui mais de 10.000 bases nitrogenadas.", CR, LF, 0
	msgNumNaoInformado	 	db      "Erro: O tamanho dos grupos nao foi informado.", CR, LF, 0
	msgNumInvalido		 	db      "Erro: O tamanho de grupos solicitado eh invalido.", CR, LF, 0
	msgNomeNaoInformado	 	db      "Erro: O nome do arquivo de entrada nao foi informado.", CR, LF, 0
	msgComandoNaoInformado 	db		"Erro: Nenhum comando foi informado.", CR, LF, 0
	msgComandoInvalido	 	db		"Erro: Comando invalido.", CR, LF, 0
	CRLF0				 	db		 CR, LF, 0
	ponto				 	db       ".", CR, LF, 0
	ponto_e_virgula			db		 ";", 0
	deu_bom					db		 "Arquivo criado com sucesso.", CR, LF, 0

; Contagem

	qtd_adenina			 		dw 		0
	qtd_timina			 		dw 		0
	qtd_citosina		 		dw		0
	qtd_guanina			 		dw		0
	qtd_adenina_mais_timina		dw		0
	qtd_citosina_mais_guanina	dw		0
	count 				 		dw		0
	linha						dw		0
	last_group_pos				dw		0
	avanco						dw		0

; Strings para o arquivo .csv

	string_A 			 				db "A;", 0
	string_T							db "T;", 0
	string_C 			 				db "C;", 0
	string_G 			 				db "G;", 0
	string_ATCG			 				db "A+T;C+G", 0
	qtd_adenina_ascii			 		db		6	dup(0)
	qtd_timina_ascii			 		db		6	dup(0)
	qtd_citosina_ascii		 			db		6	dup(0)
	qtd_guanina_ascii			 		db		6	dup(0)
	qtd_adenina_mais_timina_ascii		db		6	dup(0)
	qtd_citosina_mais_guanina_ascii		db		6	dup(0)

; Auxiliares

	cont_aux 			 dw	 	0
	cont_aux2			 dw		0
	sw_n	 			 dw	 	0
	sw_f	 			 db	 	0
	sw_m	 			 dw  	0


.code
.startup

;------------------------------------------------------------------------------------
; Programa principal:
;------------------------------------------------------------------------------------

; Passagem da linha de comando pra memória
	call	getPSP

; Leitura das informações obtidas
	lea		bx, PSP
	call	getPSPinfo
	
	call	checkPSPinfo
	jc		return_error
	
	call	atualiza_flags

; Abertura do arquivo
	lea		dx, input_file_name
	call 	fopen
	jc		open_error								; Se o arquivo foi aberto corretamente, salva handle em "file_handle"; senão, informa erro
	mov		file_handle, ax

; Leitura do arquivo, dividida em duas partes:
; 1. Contagem do total de bases / verifação dos caracteres
	call	conta_total_bases
	jc		return_error

; 2. Contagem sequencial das bases / salvamento dos resultados em um arquivo CSV
	lea		dx, output_file_name
	call	fcreate
	jc		create_error

	mov		ax, count
	sub		ax, num
	mov		last_group_pos, ax

	mov		csv_file_handle, bx						; Se o arquivo foi criado corretamente, salva handle em "file_handle"; senão, informa erro
	call	salva_resultados
	
; Fechamento dos arquivos
	mov		bx, file_handle
	call	fclose

	mov		bx, csv_file_handle
	call	fclose
	
	lea		bx, deu_bom
	call	printf_s

	.exit		0									; Retorna 0 (Programa terminou sem erros)


; Erro na abertura
open_error:
	lea		bx, msgErroOpen
	call	printf_s
	
	lea		bx, input_file_name
	call	printf_s
	
	lea		bx, ponto
	call	printf_s
	
	jmp		return_error

; Erro na criação
create_error:

	lea		bx, msgErroCreate
	call	printf_s

return_error:
	.exit		1									; Retorna 1 (Erro)


;------------------------------------------------------------------------------------
; getPSP:
;------------------------------------------------------------------------------------
; Armazena cauda da linha de comando na string "PSP".

; Observação: para o ideal funcionamento dessa subrotina, é necessário que o
; segmento extra (ES) não tenha sido alterado anteriormente e que os primeiros 0xFF
; endereços deste segmento permaneçam com o mesmo conteúdo da inicialização do programa.

getPSP		proc	near

	push	ds				; Salva informações de segmentos
	push	es

	; Início de PSP estará armazenado em ES:0x00 na inicialização do programa

	mov		ax, ds			; DS <-> ES para usar MOVSB
	mov		bx, es
	mov		ds, bx
	mov		es, ax

	; ES:0x80 armazena o tamanho (em bytes) da cauda da linha de comando.
	; A cauda da linha de comando é efetivamente armazenada no PSP a partir do offset 81H.

	mov 	si, 80H 		; Obtém o tamanho do string e coloca em CX
	mov		ch, 0
	mov 	cl, [si]

	inc		si				; SI = offset da cauda da linha de comando no PSP
	lea		di, PSP			; DI = offset da string "PSP"

	rep		movsb

	pop		es				; Retorna informações de segmentos
	pop		ds
	ret

getPSP		endp

;------------------------------------------------------------------------------------
; getPSPinfo:
;------------------------------------------------------------------------------------
; Retorna as seguintes informações da PSP:
; 1. Arquivo de entrada, armazenado na string apontada por "input_file_name";
; 2. Código de comando, armazenado na string apontada por "command_code";
; 3. Tamanho dos grupos selecionados pelo comando "-n", armazenado na variável "num".

; Entrada:
; - BX: ponteiro para string com a cauda da linha de comando.

getPSPinfo	proc	near

psp_loop:
	mov		al, [bx]
	cmp		al, CR
	jbe		psp_end			; Termina se AL <= CR

	inc		bx
	cmp		al, '-'
	je		test_command	; Testa comando se AL == '-'

	jmp		psp_loop

test_command:
	mov		al, [bx]
	cmp		al, 'f'
	je		getInputFileName

	cmp 	al, 'o'
	je		getOutputFileName

	cmp		al, 'n'
	je		getNumber

	jmp		getCommand

getInputFileName:
	mov		flag_f, 1
	add		bx, 2
	mov		si, 0

gfin_loop:
	mov		al, [bx+si]
	cmp		al, ' '
	jbe		gfin_end
	mov		input_file_name[si], al
	inc		si
	jmp		gfin_loop

gfin_end:
	mov		input_file_name[si], 0
	cmp		al, CR
	jbe		psp_end
	add		bx, si
	inc 	bx
	jmp		psp_loop

getOutputFileName:
	mov		flag_o, 1
	add		bx, 2
	mov		si, 0

gfout_loop:
	mov		al, [bx+si]
	cmp		al, ' '
	jbe		gfout_end
	mov		output_file_name[si], al
	inc		si
	jmp		gfout_loop

gfout_end:
	mov		output_file_name[si], 0
	cmp		al, CR
	jbe		psp_end
	add		bx, si
	inc 	bx
	jmp		psp_loop

getNumber:
	mov		flag_n, 1
	add		bx, 2
	mov		si, 0

get_num_loop:
	mov		al, [bx+si]
	cmp		al, ' '
	jbe		get_num_end
	mov		num_ascii[si], al
	inc		si
	jmp		get_num_loop

get_num_end:
	mov		num_ascii[si], 0
	cmp		al, CR
	jbe		psp_end
	add		bx, si
	inc 	bx
	jmp		psp_loop

getCommand:
	mov		flag_cmnd, 1
	mov		si, 0

getcmnd_loop:
	mov		al, [bx+si]
	cmp		al, ' '
	jbe		getcmnd_end
	mov		command_code[si], al
	inc		si
	jmp		getcmnd_loop

getcmnd_end:
	mov		command_code[si], 0
	cmp		al, CR
	jbe		psp_end
	add		bx, si
	inc 	bx
	jmp		psp_loop

psp_end:
	mov 	dl, flag_o
	cmp		dl, 1
	je		return_get_psp

	lea		bx, std_output_file_name		
	mov		si, 0

output_file_name_cpy:
	mov 	al, [bx + si]
	cmp		al, 0
	je		return_get_psp

	mov		output_file_name[si], al
	inc		si
	jmp		output_file_name_cpy
	

return_get_psp:

	lea		bx, num_ascii
	call 	atoi
	mov		num, ax
	ret

getPSPinfo	endp


;------------------------------------------------------------------------------------
; checkPSPinfo:
;------------------------------------------------------------------------------------
; Checa as infromações que foram fornecidas na linha de comando.

checkPSPinfo	proc	near

	mov		al, flag_f
	cmp		al, 0
	je		sem_arq_entrada
	
	mov		al, flag_n
	cmp		al, 0
	je		sem_num_grupos
	
	mov		ax, num
	cmp		ax, 0
	je		num_invalido
	
	mov		al, flag_cmnd
	cmp		al, 0
	je		sem_cod_comando
	
	lea		si, command_code

volta:
	mov		al, [si]
	cmp		al, 0
	je		fim
	
	cmp		al, 'a'
	je		beleza
	cmp		al, 't'
	je		beleza
	cmp		al, 'c'
	je		beleza
	cmp		al, 'g'
	je		beleza
	cmp		al, '+'
	je		beleza
	
	jmp		cmnd_invalido
	
beleza:
	inc		si
	jmp		volta
	
	
sem_arq_entrada:
	lea		bx, msgNomeNaoInformado
	call	printf_s
	stc
	jmp		fim
	
sem_num_grupos:
	lea		bx, msgNumNaoInformado
	call	printf_s
	stc
	jmp		fim
	
num_invalido:
	lea		bx, msgNumInvalido
	call	printf_s
	stc
	jmp		fim
	
sem_cod_comando:
	lea		bx, msgComandoNaoInformado
	call	printf_s
	stc
	jmp		fim
	
cmnd_invalido:
	lea		bx, msgComandoInvalido
	call	printf_s
	stc	
	
fim:
	ret


checkPSPinfo	endp

;
;--------------------------------------------------------------------
; atualiza_flags:
;--------------------------------------------------------------------
; Atualiza as flags com base no command_code.

atualiza_flags	proc	near

	lea		bx, command_code

af_loop:
	mov		al, [bx]
	cmp 	al, 0
	je		af_end	; Termina se AL == '\0'

	cmp		al, 'a'
	jne		teste_t
	
	mov   	flag_a, 1
	jmp		continua

teste_t:
	cmp		al, 't'
	jne		teste_c
	
	mov   	flag_t, 1
	jmp		continua

teste_c:
	cmp		al, 'c'
	jne		teste_g
	
	mov   	flag_c, 1
	jmp		continua

teste_g:
	cmp		al, 'g'
	jne		teste_mais
	
	mov   	flag_g, 1
	jmp		continua
	
teste_mais:
	cmp		al, '+'
	jne		continua	
	
	mov   	flag_add, 1
	
continua:
	inc		bx
	jmp		af_loop

af_end:
	ret

atualiza_flags	endp

;
;--------------------------------------------------------------------
; conta_total_bases:
;--------------------------------------------------------------------
; Conta o total de bases nitrogenadas no arquivo de entrada e armazena
; na variável count.

; Saídas: - CF -> Se o arquivo não possui um tamanho válido e/ou somente
; caracteres válidos, CF == 1; senão CX == 0;

conta_total_bases	proc	near

again:										; Loop para pegar byte por byte do arquivo e colocar no file_buffer

	mov			bx, file_handle				; Move conteudo de file_handle para bx
	call		fgetchar

	jnc			eof_test					; Se carry = 0, nao deu erro na leitura. Pular para conferir para  conferir se chegou ao final

	lea			bx, msgErroRead				; Senao, imprimir mensagem de erro na tela
	call		printf_s					;
	mov			al, 1						;

	mov			bx, file_handle
	call		fclose
	jmp			fim_ctb

eof_test:									; Verifica se chegou ao final do arquivo

	cmp			ax, 0
	jne			not_eof						; Se ax for diferente de 0, nao chegou ao final

	mov			al,0						; Se ax = 0, chegou ao final. Colocar 0 em al, informando que fechou corretamente

	mov			bx, file_handle
	call		fclose
	jmp			fim_ctb

not_eof:									; bora ver o que tem de bom nesse arquivo

	cmp			dl, 'A'						; será que é um 'A'?
	je			count_inc
	cmp			dl, 'C'						; ou talvez um 'C'?
	je			count_inc
	cmp			dl, 'G'						; quem sabe um 'G'?
	je			count_inc
	cmp			dl, 'T'						; um 'T', então?
	je			count_inc

	cmp			dl, CR						; opa, nova linha?
	jbe			linha_inc
											; vish...

	jne			char_invalido_meu_patrao	; pô, aí não pode parceiro

linha_inc:
	mov			cx, linha
	inc 		cx
	mov			linha, cx
	jmp			again

count_inc:
	mov			cx, count
	inc 		cx

	cmp			cx, 10000					; testando se confere com o limite aceitável de bases
	jg			que_arquivao_hein

	mov			count, cx
	jmp			again

char_invalido_meu_patrao:

	mov			bx, file_handle
	call		fclose

	; printf("Caractere invalido %c encontrado na linha %d\n", char_invalido, linha);
	lea			bx, msgCharInvalidoPt1
	call		printf_s

	mov			char_invalido, dl
	lea			bx, char_invalido
	call		printf_s

	lea			bx, msgCharInvalidoPt2
	call		printf_s

	mov			ax, linha
	lea			bx, linha_ascii
	call		sprintf_w

	lea			bx, linha_ascii
	call 		printf_s

	lea			bx, ponto
	call		printf_s

	stc										; liga a flag de carry pra informar que teve erro

	jmp			fim_ctb

que_arquivao_hein:

	mov			bx, file_handle
	call		fclose

	; puts("Arquivo muito grande.");
	lea			bx, msgArquivoMtGrande
	call		printf_s

	stc										; liga a flag de carry pra informar que teve erro

fim_ctb:
	ret

conta_total_bases	endp


;--------------------------------------------------------------------
; atoi:
;--------------------------------------------------------------------
; Converte um ASCII-DECIMAL para HEXA

; Entra: (S) -> DS:BX -> Ponteiro para o string de origem

; Sai:	(A) -> AX -> Valor "Hex" resultante

; Algoritmo:
;	A = 0;
;	while (*S!='\0') {
;		A = 10 * A + (*S - '0')
;		++S;
;	}
;	return
;--------------------------------------------------------------------

atoi	proc near

		; A = 0;
		mov		ax,0

atoi_2:
		; while (*S!='\0') {
		cmp		byte ptr[bx], 0
		jz		atoi_1

		; 	A = 10 * A
		mov		cx,10
		mul		cx

		; 	A = A + *S
		mov		ch,0
		mov		cl,[bx]
		add		ax,cx

		; 	A = A - '0'
		sub		ax,'0'

		; 	++S
		inc		bx

		;}
		jmp		atoi_2

atoi_1:
		; return
		ret

atoi	endp

;------------------------------------------------------------------------------------
; fopen:
;------------------------------------------------------------------------------------
; Abre o arquivo cujo nome está no string apontado por DX.

; Entrada:
; - DX -> ponteiro para string com nome do arquivo.

; Saídas:
; - CF -> se arquivo foi aberto, CF = 0; senão, CF = 1;
; - AX -> se arquivo foi aberto, AX = handle do arquivo; senão, AX = código de erro.

fopen		proc	near

	mov		ah, 3DH			; AH = 0x3D (Abrir arquivo)
	mov		al, 0			; AL = 0 (Apenas leitura)
	int		21H
	ret

fopen		endp

;------------------------------------------------------------------------------------
; fclose:
;------------------------------------------------------------------------------------
; Fecha o arquivo cujo handle está em BX.

; Entrada:	BX -> file handle

; Saída:	CF -> "0" se OK

fclose		proc	near

	mov		ah, 3EH			; AH = 0xEH (Fechar arquivo)
	int		21h
	ret

fclose		endp

;
;------------------------------------------------------------------------------------
; printf_s:
;------------------------------------------------------------------------------------
; Escreve uma string na tela.

; Entrada:
; - BX -> Endereço de início da string.

; Algoritmo:
; void printf_s(char *s -> BX) {
;	 While (*s!='\0') {
;		 putchar(*s)
; 		 ++s;
;	 }
; }

printf_s	proc	near

;	While (*s!='\0') {
	mov		dl,[bx]
	cmp		dl,0
	je		ps_1

;		putchar(*s)
	push	bx
	mov		ah,2
	int		21H
	pop		bx

;		++s;
	inc		bx

;	}
	jmp		printf_s

ps_1:
	ret

printf_s	endp


;--------------------------------------------------------------------
; sprintf_w:
;--------------------------------------------------------------------
;Função: Converte um inteiro (n) para (string).
;		 sprintf(string, "%d", n)
;
;void sprintf_w(char *string->BX, WORD n->AX) {
;	k=5;
;	m=10000;
;	f=0;
;	do {
;		quociente = n / m : resto = n % m;	// Usar instrução DIV
;		if (quociente || f) {
;			*string++ = quociente+'0'
;			f = 1;
;		}
;		n = resto;
;		m = m/10;
;		--k;
;	} while(k);
;
;	if (!f)
;		*string++ = '0';
;	*string = '\0';
;}
;
;Associação de variaveis com registradores e memória
;	string	-> bx
;	k		-> cx
;	m		-> sw_m dw
;	f		-> sw_f db
;	n		-> sw_n	dw
;--------------------------------------------------------------------

sprintf_w	proc	near

;void sprintf_w(char *string, WORD n) {
	mov		sw_n,ax

;	k=5;
	mov		cx,5

;	m=10000;
	mov		sw_m,10000

;	f=0;
	mov		sw_f,0

;	do {
sw_do:

;		quociente = n / m : resto = n % m;	// Usar instrução DIV
	mov		dx,0
	mov		ax,sw_n
	div		sw_m

;		if (quociente || f) {
;			*string++ = quociente+'0'
;			f = 1;
;		}
	cmp		al,0
	jne		sw_store
	cmp		sw_f,0
	je		sw_continue
sw_store:
	add		al,'0'
	mov		[bx],al
	inc		bx

	mov		sw_f,1
sw_continue:

;		n = resto;
	mov		sw_n,dx

;		m = m/10;
	mov		dx,0
	mov		ax,sw_m
	mov		bp,10
	div		bp
	mov		sw_m,ax

;		--k;
	dec		cx

;	} while(k);
	cmp		cx,0
	jnz		sw_do

;	if (!f)
;		*string++ = '0';
	cmp		sw_f,0
	jnz		sw_continua2
	mov		[bx],'0'
	inc		bx
sw_continua2:


;	*string = '\0';
	mov		byte ptr[bx],0

;}
	ret

sprintf_w	endp

;
;--------------------------------------------------------------------
; fcreate:
;--------------------------------------------------------------------
; Cria o arquivo cujo nome está no string apontado por DX
; boolean fcreate(char *FileName -> DX)

; Saidas:   BX -> handle do arquivo
;			CF -> 0, se OK

fcreate		proc	near

	mov		cx,0
	mov		ah,3Ch
	int		21h
	mov		bx,ax
	ret

fcreate		endp

;--------------------------------------------------------------------
; fgetchar:
;--------------------------------------------------------------------
; Lê um caractere do arquivo identificado pelo HANLDE BX
;		fgetchar(handle->BX)

; Entrada: 	BX -> file handle

; Saídas:   dl -> caractere
;			AX -> numero de caracteres lidos
;		 	CF -> "0" se leitura ok

fgetchar		proc	near

	mov		ah, 3Fh
	mov		cx, 1
	lea		dx, file_buffer
	int		21h
	mov		dl, file_buffer
	ret

fgetchar		endp

;--------------------------------------------------------------------
; fputchar:
;--------------------------------------------------------------------
; Entradas: BX -> file handle
;			dl -> caractere

; Saídas:   AX -> numero de caracteres escritos
;			CF -> "0" se escrita ok

fputchar		proc	near

	mov		ah, 40h
	mov		cx, 1
	mov		file_buffer, dl
	lea		dx, file_buffer
	int		21h
	ret

fputchar		endp

;--------------------------------------------------------------------
; fputs:
;--------------------------------------------------------------------
; Entradas: SI -> endereço da string
;			BX -> file handle do arquivo de saída

; Saída:    CF -> "0" se escrita ok

fputs			proc	near

laco_fputs:
    mov     dl, [si]
	cmp		dl, 0
	je		fim_fputs									

	call	fputchar
	
	inc		si
	jmp		laco_fputs

fim_fputs:
	ret

fputs			endp

;
;--------------------------------------------------------------------
; conta_bases_grupo:
;--------------------------------------------------------------------
; Lê cada base nitrogenada do arquivo sequencialmente em grupos de
; tamanho n e conta a quantidade de cada uma.

; Entrada:
; - BX -> Handle do arquivo.
; - CX -> Tamanho da sequência a ser lida.

conta_bases_grupo		proc	near

	; i = 0;
	; while (fscanf(file, " %c", &base) != EOF && i < n)
laco_interno:
	mov		cont_aux, cx			; var auxiliar pq a fgetchar usa o CX
	
	call	fgetchar
	jc		read_error
	
	cmp	     ax, 0                                                                   
	jne	     file_not_end               ;Se ax for diferente de 0, nao chegou ao final               

	mov	    al, 0                       ;Se ax = 0, chegou ao final. Colocar 0 em al, informado que fechou corretamente
	mov		bx, file_handle
	call	fclose
	

file_not_end:

	mov		cx, cont_aux
	; cmp		dl, ' '					; teste se file_handle == eof (será que precisa?)
	; je		fim
	
	cmp		cx, 0
	je		fim_laco_interno

continue:
	cmp		dl, CR					; quebra de linha não influencia a contagem
	jbe		laco_interno

	cmp		dl, 'A'
	jne		segue_1
	mov		ax, qtd_adenina				; qtd_adenina++;
	inc		ax
	mov		qtd_adenina, ax
	loop	laco_interno
	
	jmp		fim_laco_interno

segue_1:
	cmp		dl, 'T'
	jne		segue_2
	mov		ax, qtd_timina				; qtd_timina++;
	inc		ax
	mov		qtd_timina, ax
	loop    laco_interno
	
	jmp		fim_laco_interno

segue_2:
	cmp		dl, 'C'
	jne		segue_3
	mov		ax, qtd_citosina			; qtd_citosina++;
	inc		ax
	mov		qtd_citosina, ax
	loop    laco_interno
	
	jmp		fim_laco_interno

segue_3:
	cmp		dl, 'G'
	jne		fim
	mov		ax, qtd_guanina				; qtd_guanina++;
	inc		ax
	mov		qtd_guanina, ax
	loop 	laco_interno
	
	jmp		fim_laco_interno

read_error:
	lea		bx, msgErroRead
	call	printf_s

fim_laco_interno:
	ret

conta_bases_grupo		endp

;
;--------------------------------------------------------------------
; salva_resultados:
;--------------------------------------------------------------------
; Salva os resultados obtidos pela conta_bases_grupo em um arquivo CSV,
; repetindo isso com o cabeçote do arquivo reposicionado uma posição
; à frente até chegar no grupo de número count - n.

salva_resultados	proc	near

	call	salva_bases

	lea		dx, input_file_name				
	call	fopen
	jc		fim_salva_res
	mov		file_handle, ax

de_volta:
	mov		cx, avanco
	cmp		cx, 0
	je		pula
	
	cmp		cx, last_group_pos
	jg		fim_salva_res
	
	call	avanca_arquivo_entrada

pula:
	mov		bx, file_handle				; arquivo de entrada
	mov		cx, num						; tamanho dos grupos
	call	conta_bases_grupo
	
	call	salva_contagem
	
	call	reinicia_arquivo_entrada
	
	mov		ax, avanco
	inc		ax
	mov		avanco, ax
	
	jmp		de_volta

fim_salva_res:
	ret

salva_resultados	endp


;
;--------------------------------------------------------------------
; salva_bases:
;--------------------------------------------------------------------
; Função auxiliar 1 para a salva_resultados.

salva_bases		proc	 near

	mov 	ah, 0							
	mov		al, flag_a
	cmp		al, 0
	je		tst_flag_T
											
	lea		si, string_A
	mov	    bx, csv_file_handle
	call	fputs

tst_flag_T:
	mov 	ah, 0
	mov		al, flag_t
	cmp		al, 0
    je      tst_flag_C
											
    lea     si, string_T
	mov	    bx, csv_file_handle
	call	fputs


tst_flag_C:
	mov 	ah, 0
	mov		al, flag_c
	cmp		al, 0
    je      tst_flag_G
											
    lea     si, string_C
	mov	    bx, csv_file_handle
	call	fputs

tst_flag_G:
	mov 	ah, 0
	mov		al, flag_g
	cmp		al, 0
    je      tst_flag_add
											
    lea     si, string_G
	mov	    bx, csv_file_handle
	call	fputs

tst_flag_add:
	mov 	ah, 0
	mov		al, flag_add
	cmp		al, 0
    je      print_new_line
											
	lea     si, string_ATCG
	mov	    bx, csv_file_handle
	call	fputs

print_new_line:
	lea     si, CRLF0						; '/n'
	mov	    bx, csv_file_handle
	call	fputs
	
	ret
	
salva_bases		endp

;
;--------------------------------------------------------------------
; salva_contagem:
;--------------------------------------------------------------------
; Função auxiliar 2 para a salva_resultados.

salva_contagem	proc	near

					
	mov		al, flag_a
	cmp		al, 0
	je		tst2_flag_T
											;	fprintf(csv_file, %d;, qtd_adenina);

	mov		ax, qtd_adenina
	lea		bx, qtd_adenina_ascii
	call	sprintf_w

	lea		si, qtd_adenina_ascii
	mov		bx, csv_file_handle
	call	fputs
	
	mov		dl, ponto_e_virgula
	mov		bx, csv_file_handle
	call	fputchar


tst2_flag_T:
	mov		al, flag_t
	cmp		al, 0
	je		tst2_flag_C
											;	fprintf(csv_file, %d;, qtd_timina);

	mov		ax, qtd_timina
	lea		bx, qtd_timina_ascii
	call	sprintf_w

	lea		si, qtd_timina_ascii
	mov		bx, csv_file_handle
	call	fputs
	
	mov		dl, ponto_e_virgula
	mov		bx, csv_file_handle
	call	fputchar


tst2_flag_C:
	mov		al, flag_c
	cmp		al, 0
	je		tst2_flag_G
											;	fprintf(csv_file, %d;, qtd_citosina);

	mov		ax, qtd_citosina
	lea		bx, qtd_citosina_ascii
	call	sprintf_w

	lea		si, qtd_citosina_ascii
	mov		bx, csv_file_handle
	call	fputs
	
	mov		dl, ponto_e_virgula
	mov		bx, csv_file_handle
	call	fputchar


tst2_flag_G:
	mov		al, flag_g
	cmp		al, 0
	je		tst2_flag_add
											;	fprintf(csv_file, %d;, qtd_guanina);

	mov		ax, qtd_guanina
	lea		bx, qtd_guanina_ascii
	call	sprintf_w

	lea		si, qtd_guanina_ascii
	mov		bx, csv_file_handle
	call	fputs
	
	mov		dl, ponto_e_virgula
	mov		bx, csv_file_handle
	call	fputchar

tst2_flag_add:
	mov		al, flag_add
	cmp		al, 0
	je		print_new_line2
											;	fprintf(csv_file, %d;%d;, qtd_adenina + qtd_timina);

	mov		ax, qtd_adenina
	add		ax, qtd_timina
	mov		qtd_adenina_mais_timina, ax

	lea		si, qtd_adenina_mais_timina
	lea		bx, qtd_adenina_mais_timina_ascii
	call	sprintf_w

	lea		si, qtd_adenina_mais_timina_ascii
	mov		bx, csv_file_handle
	call	fputs
	
	mov		dl, ponto_e_virgula
	mov		bx, csv_file_handle
	call	fputchar

											;	fprintf(csv_file, %d;%d;, qtd_citosina + qtd_guanina);

	mov		ax, qtd_citosina
	add		ax, qtd_guanina
	mov		qtd_citosina_mais_guanina, ax

	lea		si, qtd_citosina_mais_guanina
	lea		bx, qtd_citosina_mais_guanina_ascii
	call	sprintf_w

	lea		si, qtd_citosina_mais_guanina_ascii
	mov		bx, csv_file_handle
	call	fputs
	

print_new_line2:
											; 	fprintf(csv_file,"\n");
	lea		si, CRLF0
	mov		bx, csv_file_handle
	call	fputs


	mov		ax, 0
	mov		qtd_adenina, ax
	mov		qtd_citosina, ax
	mov		qtd_timina, ax
	mov		qtd_guanina, ax
	mov		qtd_adenina_mais_timina, ax
	mov		qtd_citosina_mais_guanina, ax

	ret

salva_contagem		endp

;
;--------------------------------------------------------------------
; reinicia_arquivo_entrada:
;--------------------------------------------------------------------
; Fecha e abre novamente um arquivo.

reinicia_arquivo_entrada proc	near

	mov		bx, file_handle
	call	fclose
	
	lea		dx, input_file_name
	call	fopen
	mov		file_handle, ax

	ret
	
reinicia_arquivo_entrada endp

;
;--------------------------------------------------------------------
; avanca_arquivo_entrada:
;--------------------------------------------------------------------
; Avança em um arquivo CX posições (bytes).

avanca_arquivo_entrada	proc	near

		mov		cx, avanco
		
laco_avanco:
		mov		bx, file_handle
		
		mov		di, cx
		call	fgetchar
		mov		cx, di
		loop	laco_avanco
		
		ret

avanca_arquivo_entrada	endp


;------------------------------------------------------------------------------------
end
;------------------------------------------------------------------------------------