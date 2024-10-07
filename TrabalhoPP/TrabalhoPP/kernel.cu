#include <stdio.h>
#include <stdlib.h>
#include <time.h>
#include <cuda_runtime.h>
#include <device_launch_parameters.h>
#include <curand_kernel.h>

#define TILE_SIZE 16 // Tamanho do bloco para memória compartilhada

__global__ void multiplicaMatrizCUDA(int* matriz1, int* matriz2, int* matrizResultado, int size) {
    __shared__ int tileM[TILE_SIZE][TILE_SIZE];
    __shared__ int tileN[TILE_SIZE][TILE_SIZE];

    int linha = blockIdx.y * TILE_SIZE + threadIdx.y;
    int coluna = blockIdx.x * TILE_SIZE + threadIdx.x;
    int valor = 0;

    for (int i = 0; i < (size + TILE_SIZE - 1) / TILE_SIZE; i++) {
        // Carregar dados na memória compartilhada
        if (linha < size && (i * TILE_SIZE + threadIdx.x) < size) {
            tileM[threadIdx.y][threadIdx.x] = matriz1[linha * size + (i * TILE_SIZE + threadIdx.x)];
        }
        else {
            tileM[threadIdx.y][threadIdx.x] = 0; // Preencher com 0 se fora dos limites
        }

        if (coluna < size && (i * TILE_SIZE + threadIdx.y) < size) {
            tileN[threadIdx.y][threadIdx.x] = matriz2[(i * TILE_SIZE + threadIdx.y) * size + coluna];
        }
        else {
            tileN[threadIdx.y][threadIdx.x] = 0; // Preencher com 0 se fora dos limites
        }

        __syncthreads(); // Sincroniza os threads

        // Multiplicação das matrizes
        for (int j = 0; j < TILE_SIZE; j++) {
            valor += tileM[threadIdx.y][j] * tileN[j][threadIdx.x];
        }

        __syncthreads(); // Sincroniza os threads novamente
    }

    if (linha < size && coluna < size) {
        matrizResultado[linha * size + coluna] = valor;
    }
}

// Kernel para preencher a matriz utilizando curand
__global__ void preencheMatrizCUDA(int* matriz, int size, unsigned long long seed) {
    int linha = blockIdx.y * blockDim.y + threadIdx.y;
    int coluna = blockIdx.x * blockDim.x + threadIdx.x;

    curandState state;
    curand_init(seed, linha * size + coluna, 0, &state); // Inicializa o gerador de números aleatórios

    if (linha < size && coluna < size) {
        matriz[linha * size + coluna] = curand(&state) % 10000; // Gera um número aleatório
    }
}

int main() {
    srand(time(0));
    int tamanho;
    printf("Insira o tamanho da matriz: ");
    scanf("%d", &tamanho);

    int* h_matriz1 = (int*)malloc(tamanho * tamanho * sizeof(int));
    int* h_matriz2 = (int*)malloc(tamanho * tamanho * sizeof(int));
    int* h_matrizResultado = (int*)malloc(tamanho * tamanho * sizeof(int));

    int* d_matriz1, * d_matriz2, * d_matrizResultado;
    cudaMalloc((void**)&d_matriz1, tamanho * tamanho * sizeof(int));
    cudaMalloc((void**)&d_matriz2, tamanho * tamanho * sizeof(int));
    cudaMalloc((void**)&d_matrizResultado, tamanho * tamanho * sizeof(int));

    // Preenchendo a matriz 1 na GPU
    dim3 blocos(TILE_SIZE, TILE_SIZE);
    dim3 grades((tamanho + TILE_SIZE - 1) / TILE_SIZE, (tamanho + TILE_SIZE - 1) / TILE_SIZE);

    // Passando um valor de semente aleatório para cada chamada
    unsigned long long seed = time(0);
    preencheMatrizCUDA << <grades, blocos >> > (d_matriz1, tamanho, seed);
    preencheMatrizCUDA << <grades, blocos >> > (d_matriz2, tamanho, seed + 1);

    cudaDeviceSynchronize(); // Espera os kernels terminarem

    // Copiando matrizes de volta para a CPU
    cudaMemcpy(h_matriz1, d_matriz1, tamanho * tamanho * sizeof(int), cudaMemcpyDeviceToHost);
    cudaMemcpy(h_matriz2, d_matriz2, tamanho * tamanho * sizeof(int), cudaMemcpyDeviceToHost);

    clock_t tempoInicial = clock();
    multiplicaMatrizCUDA << <grades, blocos >> > (d_matriz1, d_matriz2, d_matrizResultado, tamanho);
    cudaDeviceSynchronize();
    clock_t tempoFinal = clock();

    double duracao = (double)(tempoFinal - tempoInicial) / CLOCKS_PER_SEC;
    printf("Tempo: %.2f clock/segundos\n", duracao);

    // Copiando o resultado da multiplicação para a CPU
    cudaMemcpy(h_matrizResultado, d_matrizResultado, tamanho * tamanho * sizeof(int), cudaMemcpyDeviceToHost);

    // Liberando memória
    free(h_matriz1);
    free(h_matriz2);
    free(h_matrizResultado);
    cudaFree(d_matriz1);
    cudaFree(d_matriz2);
    cudaFree(d_matrizResultado);

    return 0;
}
