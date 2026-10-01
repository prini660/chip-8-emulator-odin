package main

import "core:fmt"
import "core:mem"
import "core:os"

// ---------------------------------------------------------------
// HITO 1: hardware virtual
// ---------------------------------------------------------------
chip8 :: struct {
	registros:  [16]u8,
	memoria:    [4096]u8,
	indice:     u16,
	pc:         u16,
	stack:      [16]u16,
	sp:         u8,
	delaytimer: u8,
	soundtimer: u8,
	keypad:     [16]u8,
	video:      [64 * 32]u32,
	opcode:     u16,
}

DIRECCION_INICIO :: u16(0x200)
DIRECCION_FUENTE :: u16(0x50)

fuente := [80]u8{
	0xF0, 0x90, 0x90, 0x90, 0xF0,
	0x20, 0x60, 0x20, 0x20, 0x70,
	0xF0, 0x10, 0xF0, 0x80, 0xF0,
	0xF0, 0x10, 0xF0, 0x10, 0xF0,
	0x90, 0x90, 0xF0, 0x10, 0x10,
	0xF0, 0x80, 0xF0, 0x10, 0xF0,
	0xF0, 0x80, 0xF0, 0x90, 0xF0,
	0xF0, 0x10, 0x20, 0x40, 0x40,
	0xF0, 0x90, 0xF0, 0x90, 0xF0,
	0xF0, 0x90, 0xF0, 0x10, 0xF0,
	0xF0, 0x90, 0xF0, 0x90, 0x90,
	0xE0, 0x90, 0xE0, 0x90, 0xE0,
	0xF0, 0x80, 0x80, 0x80, 0xF0,
	0xE0, 0x90, 0x90, 0x90, 0xE0,
	0xF0, 0x80, 0xF0, 0x80, 0xF0,
	0xF0, 0x80, 0xF0, 0x80, 0x80,
}

cargar_fuente :: proc(chip: ^chip8) {
	mem.copy(&chip.memoria[DIRECCION_FUENTE], &fuente[0], len(fuente))
}

// Carga cualquier archivo .ch8 en la RAM a partir de 0x200.
// Devuelve la cantidad de bytes cargados.
cargar :: proc(chip: ^chip8, ruta: string) -> int {
	data, err := os.read_entire_file_from_path(ruta, context.allocator)
	if err != nil {
		fmt.eprintf("Error: El archivo %s no pudo ser cargado correctamente\n", ruta)
		os.exit(1)
	}
	defer delete(data)

	espacio_disponible := len(chip.memoria) - int(DIRECCION_INICIO)
	if len(data) > espacio_disponible {
		fmt.eprintf("Error: El archivo %s es demasiado grande para la memoria\n", ruta)
		os.exit(1)
	}

	mem.copy(&chip.memoria[DIRECCION_INICIO], raw_data(data), len(data))

	fmt.printf("Cargados %d bytes en 0x%X\n", len(data), DIRECCION_INICIO)
	return len(data)
}

// Volcado hexadecimal de la ROM cargada, 16 bytes por fila.
// El desplazamiento de la izquierda es el del ARCHIVO (como en un hex editor);
// el byte 0 del archivo vive en la RAM en 0x200.
imprimir_memoria :: proc(chip: ^chip8, tam_rom: int) {
	inicio := int(DIRECCION_INICIO)

	for i := 0; i < tam_rom; i += 16 {
		fmt.printf("%08X  ", i)
		for j := i; j < i + 16; j += 1 {
			if j < tam_rom {
				fmt.printf("%02X ", chip.memoria[inicio + j])
			} else {
				fmt.printf("   ")
			}
		}
		fmt.println()
	}
}
