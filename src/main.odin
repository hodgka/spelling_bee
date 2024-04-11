package spelling_bee

import "core:fmt"
import "core:strings"
import "core:os"
import "core:log"
import "core:math"
import "core:mem"
import "core:runtime"
import rl "vendor:raylib"

import hg "../libs/hex_grid"

PALETTE_COLOR :: enum{YELLOW, GRAY, WHITE, BLACK}

PALETTE := [PALETTE_COLOR]rl.Color{
    .YELLOW = rl.GetColor(0xf7da21FF),
    .GRAY = rl.GetColor(0xe6e6e6FF),
    .WHITE = rl.GetColor(0xFFFFFFFF),
    .BLACK = rl.GetColor(0x000000FF),
}

Tile :: struct {
    hex: hg.Hex,
    letter: string,
}

Button :: struct {
    rec: rl.Rectangle,
    text: string,
    onclick: proc(^GameState),
}

GameState :: struct {
    found_words: [dynamic]string,
    input: [dynamic]string,
    tiles: [7]Tile,
}

make_tiles :: proc(hexes: []hg.Hex, letters: []string) -> [7]Tile {
    output: [7]Tile
    soa := soa_zip(hex=hexes, letter=letters)
    for t, i in soa{
        output[i].hex = t.hex
        output[i].letter = t.letter
    }
    return output
}

draw_grid :: proc (layout: hg.Layout, tiles: [7]Tile){
    for tile in tiles {
        if tile.hex.q == 0 && tile.hex.r == 0 {
            //draw center hex
            hg.Hex_draw(layout, tile.hex, PALETTE[.YELLOW])
        }
        else {
            hg.Hex_draw(layout, tile.hex, PALETTE[.GRAY])
        }

        hg.Hex_draw_outline(layout, tile.hex, PALETTE[.WHITE], 4)
        hg.Hex_draw_label(layout, tile.hex, PALETTE[.BLACK],  fmt.ctprintf(tile.letter))
    }
}


read_dict :: proc(filename: string) -> (words: [dynamic]string, read_successful: bool) {
    data := os.read_entire_file(filename) or_return
    word_str := string(data)
    for word in strings.split_lines_iterator(&word_str) {
        append(&words, word)
    }
    return words, true

}


main :: proc() {
    track: mem.Tracking_Allocator
	mem.tracking_allocator_init(&track, context.allocator)
	defer mem.tracking_allocator_destroy(&track)
	context.allocator = mem.tracking_allocator(&track)

    
	screenWidth: i32 = 700
	screenHeight: i32 = 450
	HEX_SIZE :: 50
	ORIGIN := hg.Point{f64(screenWidth) / 2.0, f64(screenHeight) / 2.0}
	LAYOUT_SIZE := hg.Point{50, 50}
	layout := hg.Layout{hg.FLAT_ORIENTATION, LAYOUT_SIZE, ORIGIN}
    
    
	hexes := hg.make_hexagon(1)
    letters := []string{"m", "w", "b", "o", "l", "n", "e"}
    tiles := make_tiles(hexes[:], letters)
    
    dictionary, read_successful := read_dict("/usr/share/dict/words")
    if !read_successful {
        fmt.println("Could not read dictionary: {0}", dictionary)
        os.exit(1)
    }
    found_words :[dynamic]string
    current_input : [dynamic]string
    state := GameState{tiles=tiles}
    grid_bb := hg.Hexgrid_bounding_box(layout, hexes)
    fmt.println(grid_bb)
    // buttons := [3]Button{
    //     Button{}
    // }


	rl.SetConfigFlags({.WINDOW_RESIZABLE, .MSAA_4X_HINT})
	rl.InitWindow(screenWidth, screenHeight, "raylib hex grid")


	rl.SetTargetFPS(60)
	for !rl.WindowShouldClose() {
		// Update
		//----------------------------------------------------------------------------------

		//----------------------------------------------------------------------------------

		// Draw
		//----------------------------------------------------------------------------------
		rl.BeginDrawing()

		rl.ClearBackground(PALETTE[.WHITE])
		draw_grid(layout, tiles)

        // draw_buttons()
        rl.DrawRectangleLines(i32(grid_bb[0].x), i32(grid_bb[0].y),
            i32(grid_bb[1].x - grid_bb[0].x), i32(grid_bb[1].y - grid_bb[0].y), rl.BLACK)

        text := fmt.ctprintf("Mouse pos: ({0:.2f},{1:.2f})", rl.GetMousePosition().x, rl.GetMousePosition().y)
        rl.DrawText(text, 100, 100, 20, PALETTE[.BLACK])
        text = fmt.ctprintf(
            "BB pos: top_left=({0:.2f},{1:.2f}), bot_right=({2:.2f},{3:.2f})",
            grid_bb[0].x, grid_bb[0].y,
            grid_bb[1].x, grid_bb[1].y,
        )
        rl.DrawText(text, 100, 130, 20, PALETTE[.BLACK])
        // text := rl.TextFormat("Mouse pos: %")
		rl.EndDrawing()
	}

	rl.CloseWindow()

	delete(hexes)
	for _, leak in track.allocation_map {
		fmt.printf("%v leaked %m\n", leak.location, leak.size)
	}
	for bad_free in track.bad_free_array {
		fmt.printf(
			"%v allocation %p was freed badly\n",
			bad_free.location,
			bad_free.memory,
		)
	}
}