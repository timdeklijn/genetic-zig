const std = @import("std");
const rl = @import("raylib");
const rg = @import("raygui");
const rand = std.crypto.random;
const Population = @import("genetic.zig").Population;

const SCREEN_WIDTH: i32 = 800;
const SCREEN_HEIGHT: i32 = 800;

// TODO: these values should be user input
/// String to evolve towards
const TARGET: []const u8 = "Hello, World!";
/// Length of target string
const LENGTH: usize = TARGET.len;
/// Size of the population
const POP_SIZE: usize = 300;

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const alloc = arena.allocator();

    var pop = try Population.init(alloc, POP_SIZE, LENGTH, TARGET);
    defer pop.deinit();

    var print_buf: [200:0]u8 = undefined;

    var gen: usize = 0;
    const running: bool = false;

    // rg.setStyle(rg.Control, @intFromEnum(rg.GuiDefaultProperty.TEXT_SIZE), 50);
    // rg.guiSetStyle(rg.GuiControl.DEFAULT, @intFromEnum(rg.GuiDefaultProperty.TEXT_SIZE), 50);

    var text_box_buffer: [80:0]u8 = [_:0]u8{0} ** 80;
    const text_box_text: []const u8 = "Hello, World!";
    @memcpy(text_box_buffer[0..text_box_text.len], text_box_text);

    rl.initWindow(SCREEN_WIDTH, SCREEN_HEIGHT, "Genetic Algorithm");
    defer rl.closeWindow();
    rl.setTargetFPS(60);

    rg.loadStyleDefault();
    rg.setStyle(.default, .{ .default = .text_size }, 50);

    while (!rl.windowShouldClose()) {
        rl.beginDrawing();
        defer rl.endDrawing();

        _ = rg.textBox(rl.Rectangle{ .x = 40.0, .y = 40.0, .width = 720, .height = 70 }, &text_box_buffer, text_box_buffer.len, true);

        if (running) {
            try pop.nextGeneration();
            // TODO: get the top n back.
            const ind = pop.getBest();

            const gen_string = try std.fmt.bufPrintZ(&print_buf, "{d:<5}: {s} - {d:.3}", .{ gen, ind.dna.seq.items, ind.dna.score });
            rl.drawText(gen_string, 40, 400, 50, .black);
        }

        rl.clearBackground(.white);
        gen += 1;
    }
}
