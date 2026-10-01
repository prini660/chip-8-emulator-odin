package main

import "core:fmt"

fetch :: proc(chip: ^chip8) -> u16 {
	alto := u16(chip.memoria[chip.pc & 0xFFF])
	bajo := u16(chip.memoria[(chip.pc + 1) & 0xFFF])

	chip.opcode = (alto << 8) | bajo
	chip.pc += 2

	return chip.opcode
}

decodificar :: proc(op: u16) -> string {
	x   := (op & 0x0F00) >> 8
	y   := (op & 0x00F0) >> 4
	n   := op & 0x000F
	nn  := op & 0x00FF
	nnn := op & 0x0FFF

	switch (op & 0xF000) >> 12 {
	case 0x0:
		switch op {
		case 0x00E0: return "Limpiar pantalla"
		case 0x00EE: return "Retornar de subrutina"
		}
		return fmt.tprintf("SYS 0x%03X (ignorada por emuladores modernos)", nnn)

	case 0x1: return fmt.tprintf("Saltar a 0x%03X", nnn)
	case 0x2: return fmt.tprintf("Llamar subrutina en 0x%03X", nnn)
	case 0x3: return fmt.tprintf("Saltar siguiente instrucción si V%X == 0x%02X", x, nn)
	case 0x4: return fmt.tprintf("Saltar siguiente instrucción si V%X != 0x%02X", x, nn)
	case 0x5:
		if n == 0 { return fmt.tprintf("Saltar siguiente instrucción si V%X == V%X", x, y) }

	case 0x6: return fmt.tprintf("Establecer registro V%X a 0x%02X", x, nn)
	case 0x7: return fmt.tprintf("Sumar 0x%02X al registro V%X", nn, x)

	case 0x8:
		switch n {
		case 0x0: return fmt.tprintf("V%X = V%X", x, y)
		case 0x1: return fmt.tprintf("V%X = V%X OR V%X", x, x, y)
		case 0x2: return fmt.tprintf("V%X = V%X AND V%X", x, x, y)
		case 0x3: return fmt.tprintf("V%X = V%X XOR V%X", x, x, y)
		case 0x4: return fmt.tprintf("V%X += V%X (VF = acarreo)", x, y)
		case 0x5: return fmt.tprintf("V%X -= V%X (VF = no hubo préstamo)", x, y)
		case 0x6: return fmt.tprintf("V%X >>= 1 (VF = bit perdido)", x)
		case 0x7: return fmt.tprintf("V%X = V%X - V%X (VF = no hubo préstamo)", x, y, x)
		case 0xE: return fmt.tprintf("V%X <<= 1 (VF = bit perdido)", x)
		}

	case 0x9:
		if n == 0 { return fmt.tprintf("Saltar siguiente instrucción si V%X != V%X", x, y) }

	case 0xA: return fmt.tprintf("Establecer registro I a 0x%03X", nnn)
	case 0xB: return fmt.tprintf("Saltar a 0x%03X + V0", nnn)
	case 0xC: return fmt.tprintf("V%X = número aleatorio AND 0x%02X", x, nn)
	case 0xD: return fmt.tprintf("Dibujar sprite de %d bytes en (V%X, V%X)", n, x, y)

	case 0xE:
		switch nn {
		case 0x9E: return fmt.tprintf("Saltar siguiente si la tecla V%X está presionada", x)
		case 0xA1: return fmt.tprintf("Saltar siguiente si la tecla V%X NO está presionada", x)
		}

	case 0xF:
		switch nn {
		case 0x07: return fmt.tprintf("V%X = delay timer", x)
		case 0x0A: return fmt.tprintf("Esperar una tecla y guardarla en V%X", x)
		case 0x15: return fmt.tprintf("Delay timer = V%X", x)
		case 0x18: return fmt.tprintf("Sound timer = V%X", x)
		case 0x1E: return fmt.tprintf("I += V%X", x)
		case 0x29: return fmt.tprintf("I = dirección del sprite del dígito V%X", x)
		case 0x33: return fmt.tprintf("Guardar BCD de V%X en [I], [I+1], [I+2]", x)
		case 0x55: return fmt.tprintf("Guardar V0..V%X en memoria desde I", x)
		case 0x65: return fmt.tprintf("Cargar V0..V%X desde memoria en I", x)
		}
	}

	return "Opcode desconocido (¿datos o sprite?)"
}

decodificar_rom :: proc(chip: ^chip8, tam_rom: int) {
	fin := int(DIRECCION_INICIO) + tam_rom
	chip.pc = DIRECCION_INICIO

	for int(chip.pc) + 1 < fin {
		pc_actual := chip.pc
		op := fetch(chip)

		fmt.printf(
			"PC: 0x%03X | Opcode: %04X | Decodificado: %s\n",
			pc_actual, op, decodificar(op),
		)

		free_all(context.temp_allocator)
	}
}
