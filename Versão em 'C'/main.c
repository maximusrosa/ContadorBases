#include <stdio.h>
#include <string.h>
#include <stdlib.h>

int main(int argv , char *argc[])
{
    char cod_comando[50];
    char nome_arq_entrada[50];
    char nome_arq_saida[50] = "a.out";
    char base;
    int adenina = 0, timina = 0, citosina = 0, guanina = 0;
    int i, j, n;
    short int flags [5] = {0, 0, 0, 0, 0}; // 'a', 't', 'c', 'g', '+'
    int count = 0;

    // tratamento das informações da linha de comando
    for (i = 1; i < argv; i++)
    {
        if (strcmp(argc[i], "-f") == 0)
            strcpy(nome_arq_entrada, argc[i + 1]);

        else if (strcmp(argc[i], "-o") == 0)
            strcpy(nome_arq_saida, argc[i + 1]);

        else if (strcmp(argc[i], "-n") == 0)
            n = atoi(argc[i + 1]);

        else
            strcpy(cod_comando, argc[i]);
    }

    // análise do comando solicitado
    for (j = 0; cod_comando[j] != NULL; j++)
    {
        switch (cod_comando[j])
        {
            case 'a':
                flags[0] = 1;
                break;
            case 't':
                flags[1] = 1;
                break;
            case 'c':
                flags[2] = 1;
                break;
            case 'g':
                flags[3] = 1;
                break;
            case '+':
                flags[4] = 1;
                break;
            default:
                break;
        }
    }

    FILE *file;
    // tratamento do arquivo de entrada
    file = fopen(nome_arq_entrada, "r");
    if (file == NULL) {
        printf("Erro ao abrir o arquivo.\n");
        return 1;
    }

    int linha = 1;
    // conta quantas bases têm no arquivo
    while (fscanf(file, " %c", &base) != EOF)
    {
        if (count <= 10000)
        {
            if (base == 'A' || base == 'T' || base == 'C' || base == 'G')
            {
                count++;
                continue;
            }
            else if (base == '\n')
            {
                linha++;
            }
            else
            {
                printf("Caractere invalido encontrado na linha %d.\n", linha);
                return 1;
            }
        }
        else
        {
            printf("Arquivo muito grande.\n");
            return 1;
        }
    }

    // escrever na tela a total de bases nitrogenadas encontradas
    printf("Total: %d\n", count);

    rewind(file);

    // salvar os resultados em um arquivo CSV
    FILE *csv_file = fopen(nome_arq_saida, "w");
    if (csv_file == NULL)
    {
        printf("Erro ao criar o arquivo CSV.\n");
        return 1;
    }

    // primeira linha do arquivo de saída
    if (flags[0] == 1)
        fprintf(csv_file,"A;");
    if (flags[1] == 1)
        fprintf(csv_file,"T;");
    if (flags[2] == 1)
        fprintf(csv_file,"C;");
    if (flags[3] == 1)
        fprintf(csv_file,"G;");

    if (flags[4] == 1)
        fprintf(csv_file,"A+T;C+G");

    fprintf(csv_file,"\n");

    // ler cada base nitrogenada do arquivo em sequência em grupos de tamanho n e contar a quantidade de cada uma, e
    // então repetir isso com o cabeçote do arquivo reposicionado uma posição à frente até chegar no grupo de número count - n

    for (j = 1; j <= (count - n) + 1; j++)
    {
        i = 0;

        while (fscanf(file, " %c", &base) != EOF && i < n)
        {
            switch (base) {
                case 'A':
                    adenina++;
                    i++;
                    continue;
                case 'T':
                    timina++;
                    i++;
                    continue;
                case 'C':
                    citosina++;
                    i++;
                    continue;
                case 'G':
                    guanina++;
                    i++;
                    continue;
                default:
                    break;
            }
        }

        // quantidade de bases nitrogenadas solicitadas
        if (flags[0] == 1)
            fprintf(csv_file,"%d;", adenina);
        if (flags[1] == 1)
            fprintf(csv_file,"%d;", timina);
        if (flags[2] == 1)
            fprintf(csv_file,"%d;", citosina);
        if (flags[3] == 1)
            fprintf(csv_file,"%d;", guanina);

        if (flags[4] == 1)
            fprintf(csv_file,"%d;%d", adenina + timina, citosina + guanina);

        fprintf(csv_file,"\n");

        // zerar as bases nitrogenadas
        adenina = 0;
        timina = 0;
        citosina = 0;
        guanina = 0;

        fseek(file, j, SEEK_SET);
    }


    // Fechar os arquivos de entrada e saída
    fclose(file);
    fclose(csv_file);


    printf("Deu bom");

    return 0;
}
