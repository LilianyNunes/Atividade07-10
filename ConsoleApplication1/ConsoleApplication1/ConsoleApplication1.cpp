
#include <iostream>
#include <time.h>
#include <cstdlib>
#include <ctime>
#include <chrono>

int geraAleatorio() {
    
    return std:: rand() % 10000;
}

void multiplicaMatriz(int * matriz1, int * matriz2, int * matrizResultado, int size) {
    for (int i = 0; i < size; i++) {
        for (int j = 0; j < size; j++) {
            matrizResultado[i * size + j] = 0;
            for (int x = 0; x < size; x++) {
                matrizResultado[i * size + j] += matriz1[i * size + x] * matriz2[x * size + j];
            }
        }
    }
}

void preencheMatriz(int* matriz1, int size) {
    for (int i = 0; i < size; i++) {
        for (int j = 0; j < size; j++) {
            matriz1[i * size + j] = geraAleatorio();
        }
    }
}



int main()
{
    std::cout << "Insira o tamanho da matriz: ";
    std::srand(time(0));
    int tamanho;
    std::cin >> tamanho;
    int* matriz1 = new int[tamanho * tamanho];
    int* matriz2 = new int[tamanho * tamanho];
    int* matriz3 = new int[tamanho * tamanho];
    preencheMatriz(matriz1, tamanho);
    preencheMatriz(matriz2, tamanho);
    auto tempoInicial = std::chrono::high_resolution_clock::now();
    multiplicaMatriz(matriz1, matriz2, matriz3, tamanho);
    auto tempoFinal = std::chrono::high_resolution_clock::now();
    auto duracao = tempoFinal - tempoInicial;
    auto duracaoNano = std::chrono::duration_cast<std::chrono::milliseconds>(duracao).count();
    std::cout << duracaoNano << " milisegundos" << std::endl;
    

  





    delete[] matriz1;
    delete[] matriz2;
    delete[] matriz3;
}

