# ContadorBases
Contador de bases nitrogenadas feito em Assembly para o montador MASM, seguindo a arquitetura do processador INTEL 8086, juntamente com seu protótipo feito na linguagem 'C'. O projeto foi desenvolvido na disciplina "Arquitetura e Organização de Computadores I" da UFRGS, semestre 2023/1.

Esse programa requer o sistema operacional DOS para rodar, podendo ser emulado através do DOSBOX. É necessário montar o programa através do MASM 6.11.

Chamda do programa:
trabalho.asm [parametros]

parametros obrigatórios:
-f [nome do arquivo de origem com as bases]
-n [inteiro] (tamanho dos grupos para processamento de bases)
-actg+ (pode ser usada qualquer combinação dessas letras. Elas indicam quais bases devem ser mostradas no arquivo de saída. O "+" indica que devem ser mostradas as somas "A+T" e "C+G"

parâmetros opcionais:
-o [nome do arquivo de saída] (se não for informado será gerado um arquivo chamado a.out)

O documento Intel_2023_1 contém mais informações sobre a especificação do programa.
