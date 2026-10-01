package main

import "core:math/rand"


ejecutar :: proc(chip: ^chip8, op: u16) {
	x   := (op & 0x0F00) >> 8
	y   := (op & 0x00F0) >> 4
	n   := op & 0x000F
	nn  := u8(op & 0x00FF)
	nnn := op & 0x0FFF

	switch (op & 0xF000) >> 12 {
	case 0x0:
		if op == 0x00E0 {
			for i := 0; i < len(chip.video); i += 1 {
				chip.video[i] = 0
			}
		} else if op == 0x00EE {
			chip.sp -= 1
			chip.pc = chip.stack[chip.sp]
		}

	case 0x1:
		chip.pc = nnn

	case 0x2:
		chip.stack[chip.sp] = chip.pc
		chip.sp += 1
		chip.pc = nnn

	case 0x3:
		if chip.registros[x] == nn { chip.pc += 2 }

	case 0x4:
		if chip.registros[x] != nn { chip.pc += 2 }

	case 0x5:
		if n == 0 && chip.registros[x] == chip.registros[y] { chip.pc += 2 }

	case 0x6:
		chip.registros[x] = nn

	case 0x7:
		chip.registros[x] += nn

	case 0x8:
		vx := chip.registros[x]
		vy := chip.registros[y]

		switch n {
		case 0x0: chip.registros[x] = vy
		case 0x1: chip.registros[x] = vx | vy
		case 0x2: chip.registros[x] = vx & vy
		case 0x3: chip.registros[x] = vx ~ vy

		case 0x4:
			suma := u16(vx) + u16(vy)
			chip.registros[x] = u8(suma)
			if suma > 0xFF {
				chip.registros[0xF] = 1
			} else {
				chip.registros[0xF] = 0
			}

		case 0x5:
			chip.registros[x] = vx - vy
			if vx >= vy {
				chip.registros[0xF] = 1
			} else {
				chip.registros[0xF] = 0
			}

		case 0x6:
			bit := vx & 0x1
			chip.registros[x] = vx >> 1
			chip.registros[0xF] = bit

		case 0x7:
			chip.registros[x] = vy - vx
			if vy >= vx {
				chip.registros[0xF] = 1
			} else {
				chip.registros[0xF] = 0
			}

		case 0xE:
			bit := (vx >> 7) & 0x1
			chip.registros[x] = vx << 1
			chip.registros[0xF] = bit
		}

	case 0x9:
		if n == 0 && chip.registros[x] != chip.registros[y] { chip.pc += 2 }

	case 0xA:
		chip.indice = nnn

	case 0xB:
		chip.pc = nnn + u16(chip.registros[0])

	case 0xC:
		chip.registros[x] = u8(rand.uint32() & 0xFF) & nn

	case 0xD:
		x_inicio := int(chip.registros[x]) % 64
		y_inicio := int(chip.registros[y]) % 32
		chip.registros[0xF] = 0

		for fila := 0; fila < int(n); fila += 1 {
			py := y_inicio + fila
			if py >= 32 { break }

			byte_sprite := chip.memoria[(int(chip.indice) + fila) % 4096]

			for columna := 0; columna < 8; columna += 1 {
				px := x_inicio + columna
				if px >= 64 { break }

				if (byte_sprite >> uint(7 - columna)) & 0x1 == 1 {
					i := py * 64 + px
					if chip.video[i] == 0xFFFFFFFF {
						chip.registros[0xF] = 1
					}
					chip.video[i] ~= 0xFFFFFFFF
				}
			}
		}

	case 0xE:
		tecla := chip.registros[x] & 0xF
		if nn == 0x9E {
			if chip.keypad[tecla] != 0 { chip.pc += 2 }
		} else if nn == 0xA1 {
			if chip.keypad[tecla] == 0 { chip.pc += 2 }
		}

	case 0xF:
		switch nn {
		case 0x07: chip.registros[x] = chip.delaytimer

		case 0x0A:
			presionada := false
			for i := 0; i < 16; i += 1 {
				if chip.keypad[i] != 0 {
					chip.registros[x] = u8(i)
					presionada = true
					break
				}
			}
			if !presionada { chip.pc -= 2 }

		case 0x15: chip.delaytimer = chip.registros[x]
		case 0x18: chip.soundtimer = chip.registros[x]
		case 0x1E: chip.indice += u16(chip.registros[x])
		case 0x29: chip.indice = DIRECCION_FUENTE + u16(chip.registros[x] & 0xF) * 5

		case 0x33:
			valor := chip.registros[x]
			chip.memoria[chip.indice]     = valor / 100
			chip.memoria[chip.indice + 1] = (valor / 10) % 10
			chip.memoria[chip.indice + 2] = valor % 10

		case 0x55:
			for i := 0; i <= int(x); i += 1 {
				chip.memoria[chip.indice + u16(i)] = chip.registros[i]
			}

		case 0x65:
			for i := 0; i <= int(x); i += 1 {
				chip.registros[i] = chip.memoria[chip.indice + u16(i)]
			}
		}
	}
}

update_timers :: proc(chip: ^chip8) {
	if chip.delaytimer > 0 { chip.delaytimer -= 1 }
	if chip.soundtimer > 0 { chip.soundtimer -= 1 }
}
