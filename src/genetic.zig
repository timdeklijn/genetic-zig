const std = @import("std");
const ArrayList = std.ArrayList;
const rand = std.crypto.random;

// TODO: Make configurable at some point
const MUT_PROB: f32 = 0.005;

/// Individual is an object that has a DNA sequence and a score. Based on their
/// score they can be selected and they can be breed.
const Individual = struct {
    id: usize,
    length: usize,
    dna: struct {
        seq: ArrayList(u8),
        score: f32,
    },

    /// Score calculates the score of the individuals dna sequence.
    fn score(ind: *Individual, target: []const u8) void {
        var i: usize = 0;
        var local_score: f32 = 0;
        while (i < ind.length) : (i += 1) {
            if (ind.dna.seq.items[i] == target[i]) local_score += 1.0;
        }
        ind.dna.score = local_score / @as(f32, @floatFromInt(ind.length));
    }

    // Init creates a new individual with a random dna sequence and score.
    fn init(
        alloc: std.mem.Allocator,
        id: usize,
        length: usize,
        target: []const u8,
    ) !Individual {
        var seq = try ArrayList(u8).initCapacity(alloc, length);
        var i: usize = 0;
        while (i < length) : (i += 1) {
            try seq.append(alloc, rand.intRangeAtMost(u8, 32, 126));
        }
        var ind = Individual{
            .id = id,
            .length = length,
            .dna = .{ .seq = seq, .score = 0.0 },
        };
        ind.score(target);
        return ind;
    }

    fn deinit(ind: *Individual, alloc: std.mem.Allocator) void {
        ind.dna.seq.deinit(alloc);
    }
};

/// Container for a group of individuals.
pub const Population = struct {
    alloc: std.mem.Allocator,
    pop_size: usize,
    pop: ArrayList(Individual),
    target: []const u8,
    length: usize,

    /// Initialize a group of individuals.
    pub fn init(
        alloc: std.mem.Allocator,
        pop_size: usize,
        length: usize,
        target: []const u8,
    ) !Population {
        var pop = try ArrayList(Individual).initCapacity(alloc, pop_size);
        for (0..pop_size) |i| {
            const ind = try Individual.init(alloc, i, length, target);
            try pop.append(alloc, ind);
            // try pop.append(Individual.init(i));
        }
        return .{
            .alloc = alloc,
            .pop_size = pop_size,
            .pop = pop,
            .target = target,
            .length = length,
        };
    }

    /// Combine the dna of two individuals, creating a new one.
    fn breed(p: *Population, id: usize, a: Individual, b: Individual) !Individual {
        // Where to split the two sequences
        const split: usize = rand.uintAtMost(usize, p.length);

        // Create a new sequence and copy the splits into it
        var seq = try ArrayList(u8).initCapacity(p.alloc, p.length);
        for (0..p.length) |i| {
            // Mutate the gene, do not inherit from parents
            if (rand.float(f32) < MUT_PROB) {
                try seq.append(p.alloc, rand.intRangeAtMost(u8, 32, 126));
                continue;
            }

            // Dependiing on the split, inherit from a or b
            if (i <= split) {
                try seq.append(p.alloc, a.dna.seq.items[i]);
            } else {
                try seq.append(p.alloc, b.dna.seq.items[i]);
            }
        }

        // Create and return a new individual
        var new = Individual{
            .id = id,
            .length = a.length,
            .dna = .{ .seq = seq, .score = 0.0 },
        };
        new.score(p.target);

        return new;
    }

    /// Based on the score of the individuals, select one.
    pub fn weightedChoice(p: *Population) Individual {
        var total_score: f32 = 0;
        for (p.pop.items) |ind| total_score += ind.dna.score;

        const r: f32 = rand.float(f32) * total_score;
        var current_sum: f32 = 0.0;

        for (p.pop.items, 0..) |ind, i| {
            current_sum += ind.dna.score;
            if (r < current_sum) return p.pop.items[i];
        }
        // Select random individual if none of the individuals have any score.
        if (current_sum == 0.0) {
            return p.pop.items[rand.uintLessThan(usize, p.pop_size)];
        }
        return p.pop.items[p.pop.items.len - 1];
    }

    /// Select two individuals, breed them to a new one and override the current
    /// population.
    pub fn nextGeneration(p: *Population) !void {
        var new_pop = try ArrayList(Individual).initCapacity(p.alloc, p.pop_size);
        for (0..p.pop_size) |i| {
            var a: Individual = undefined;
            var b: Individual = undefined;
            while (true) {
                a = p.weightedChoice();
                b = p.weightedChoice();
                if (a.id != b.id) break;
            }
            const new_ind = try p.breed(i, a, b);
            try new_pop.append(p.alloc, new_ind);
        }
        p.pop.deinit(p.alloc);
        p.pop = new_pop;
    }

    pub fn getBest(p: *Population) Individual {
        var best_score: f32 = 0;
        var index: usize = 0;
        for (p.pop.items, 0..p.pop_size) |ind, i| {
            if (ind.dna.score > best_score) {
                best_score = ind.dna.score;
                index = i;
            }
        }
        return p.pop.items[index];
    }

    pub fn deinit(p: *Population) void {
        for (p.pop.items) |*ind| {
            ind.deinit(p.alloc);
        }
        p.pop.deinit(p.alloc);
    }
};
