#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "ej1.h"

/**
 * Marca el ejercicio 1A como hecho (`true`) o pendiente (`false`).
 *
 * Funciones a implementar:
 *   - es_indice_ordenado
 */
bool EJERCICIO_1A_HECHO = false;

/**
 * Marca el ejercicio 1B como hecho (`true`) o pendiente (`false`).
 *
 * Funciones a implementar:
 *   - indice_a_inventario
 */
bool EJERCICIO_1B_HECHO = false;

/**
 * OPCIONAL: implementar en C
 */
bool es_indice_ordenado(item_t** inventario, uint16_t* indice, uint16_t tamanio, comparador_t comparador) {
	uint16_t i = 0;
	uint16_t actual_indice_vista;
	uint16_t next_indice_vista;
	bool ordenado;
	while(i < tamanio - 1){
		uint16_t actual_indice_vista = indice[i];
		uint16_t next_indice_vista = indice[i+1];

		ordenado = comparador(inventario[actual_indice_vista], inventario[next_indice_vista]);
		if(!(ordenado)){
			return false;
		}
		i++;
	}
	return true;
}

/**
 * OPCIONAL: implementar en C
 */
item_t** indice_a_inventario(item_t** inventario, uint16_t* indice, uint16_t tamanio) {

	// ¿Cuánta memoria hay que pedir para el resultado? -> tamanio * sizeof(item_t*) = tamanio * 8
	item_t** resultado = malloc(tamanio * sizeof(item_t*));
	uint16_t i = 0;
	while(i < tamanio){
		uint16_t indice_vista = indice[i];
		item_t* item_vista = inventario[indice_vista];
		resultado[i] = item_vista;
		i++;
	}
	return resultado;
}
