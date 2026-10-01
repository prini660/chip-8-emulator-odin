package main

import "core:fmt"
import "core:os"
import sdl "vendor:sdl2"

WIDTH  :: 64
HEIGHT :: 32

ESCALA        :: 10
WINDOW_WIDTH  :: WIDTH * ESCALA
WINDOW_HEIGHT :: HEIGHT * ESCALA

CICLOS_POR_FRAME :: 12


key_to_chip8 :: proc(key: sdl.Scancode) -> (u8, bool) {
	#partial switch key {
	case .NUM1: return 0x1, true
	case .NUM2: return 0x2, true
	case .NUM3: return 0x3, true
	case .NUM4: return 0xC, true

	case .Q: return 0x4, true
	case .W: return 0x5, true
	case .E: return 0x6, true
	case .R: return 0xD, true

	case .A: return 0x7, true
	case .S: return 0x8, true
	case .D: return 0x9, true
	case .F: return 0xE, true

	case .Z: return 0xA, true
	case .X: return 0x0, true
	case .C: return 0xB, true
	case .V: return 0xF, true
	}
	return 0, false
}

update_input :: proc(keypad: ^[16]u8, event: ^sdl.Event) -> bool {
	#partial switch event.type {
	case .KEYDOWN:
		if event.key.keysym.scancode == .ESCAPE {
			return false
		}
		if key, ok := key_to_chip8(event.key.keysym.scancode); ok {
			keypad[key] = 1
		}

	case .KEYUP:
		if key, ok := key_to_chip8(event.key.keysym.scancode); ok {
			keypad[key] = 0
		}
	}
	return true
}


draw_display :: proc(renderer: ^sdl.Renderer, video: ^[WIDTH * HEIGHT]u32) {
	sdl.SetRenderDrawColor(renderer, 0, 0, 0, 255)
	sdl.RenderClear(renderer)

	sdl.SetRenderDrawColor(renderer, 255, 255, 255, 255)

	for y in 0 ..< HEIGHT {
		for x in 0 ..< WIDTH {
			if video[y * WIDTH + x] == 0 {
				continue
			}
			rect := sdl.Rect{x = i32(x), y = i32(y), w = 1, h = 1}
			sdl.RenderFillRect(renderer, &rect)
		}
	}

	sdl.RenderPresent(renderer)
}



main :: proc() {
	if len(os.args) < 2 {
		fmt.println("Uso: chip8 <archivo.ch8> [--decodificar]")
		os.exit(1)
	}

	chip: chip8
	chip.pc = DIRECCION_INICIO
	cargar_fuente(&chip)
	tam := cargar(&chip, os.args[1])

	if len(os.args) > 2 && os.args[2] == "--decodificar" {
		imprimir_memoria(&chip, tam)
		decodificar_rom(&chip, tam)
		return
	}

	if sdl.Init({.VIDEO}) != 0 {
		fmt.eprintln("SDL_Init failed:", sdl.GetError())
		return
	}
	defer sdl.Quit()

	window := sdl.CreateWindow(
		"CHIP-8",
		sdl.WINDOWPOS_UNDEFINED,
		sdl.WINDOWPOS_UNDEFINED,
		WINDOW_WIDTH,
		WINDOW_HEIGHT,
		{.SHOWN, .RESIZABLE},
	)
	if window == nil {
		fmt.eprintln("SDL_CreateWindow failed:", sdl.GetError())
		return
	}
	defer sdl.DestroyWindow(window)

	renderer := sdl.CreateRenderer(window, -1, {.ACCELERATED})
	if renderer == nil {
		fmt.eprintln("SDL_CreateRenderer failed:", sdl.GetError())
		return
	}
	defer sdl.DestroyRenderer(renderer)

	if sdl.RenderSetLogicalSize(renderer, WIDTH, HEIGHT) != 0 {
		fmt.eprintln("RenderSetLogicalSize failed:", sdl.GetError())
		return
	}

	TICK :: 1.0 / 60.0
	freq := f64(sdl.GetPerformanceFrequency())
	ultimo := sdl.GetPerformanceCounter()
	acumulado: f64 = 0

	running := true
	for running {
		event: sdl.Event
		for sdl.PollEvent(&event) {
			if event.type == .QUIT {
				running = false
				continue
			}
			if !update_input(&chip.keypad, &event) {
				running = false
			}
		}

		ahora := sdl.GetPerformanceCounter()
		acumulado += f64(ahora - ultimo) / freq
		ultimo = ahora

		redibujar := false
		for acumulado >= TICK {
			acumulado -= TICK

			for _ in 0 ..< CICLOS_POR_FRAME {
				op := fetch(&chip)
				ejecutar(&chip, op)
			}
			update_timers(&chip)
			redibujar = true
		}

		if redibujar {
			draw_display(renderer, &chip.video)
		}

		sdl.Delay(1)
	}
}
