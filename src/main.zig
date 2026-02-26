const std = @import("std");
const rl = @import("raylib");
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

    rl.initWindow(SCREEN_WIDTH, SCREEN_HEIGHT, "Genetic Algorithm");
    defer rl.closeWindow();
    rl.setTargetFPS(60);

    while (!rl.windowShouldClose()) {
        rl.beginDrawing();
        defer rl.endDrawing();

        try pop.nextGeneration();
        // TODO: get the top n back.
        const ind = pop.getBest();

        const gen_string = try std.fmt.bufPrintZ(&print_buf, "{d:<5}: {s} - {d:.3}", .{ gen, ind.dna.seq.items, ind.dna.score });
        rl.drawText(gen_string, 40, 400, 50, .black);

        rl.clearBackground(.white);
        gen += 1;
    }
}
