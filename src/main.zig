const std = @import("std");
const rand = std.crypto.random;

/// String to evolve towards
const TARGET: []const u8 = "Hello, World";
/// Length of target string
const LENGTH: usize = TARGET.len;
/// Size of the population
const POP_SIZE: usize = 100;
/// Number of generations to evolve for
const GENERATIONS: usize = 5000;
/// Probability to evolve a single base in a sequence
const MUT_PROP: f32 = 0.01;

/// Individual is an object that has a DNA sequence and a score. Based on their
/// score they can be selected and they can be breed.
const Individual = struct {
    id: usize,
    dna: struct {
        seq: [LENGTH]u8,
        score: f32,
    },

    /// Score calculates the score of the individuals dna sequence.
    fn score(ind: *Individual) void {
        var i: usize = 0;
        var local_score: f32 = 0;
        while (i < LENGTH) : (i += 1) {
            if (ind.dna.seq[i] == TARGET[i]) local_score += 1.0;
        }
        ind.dna.score = local_score / LENGTH;
    }

    // Init creates a new individual with a random dna sequence and score.
    fn init(id: usize) Individual {
        var seq: [LENGTH]u8 = undefined;
        var i: usize = 0;
        while (i < LENGTH) : (i += 1) {
            seq[i] = rand.intRangeAtMost(u8, 32, 126);
        }
        var ind = Individual{ .id = id, .dna = .{ .seq = seq, .score = 0.0 } };
        ind.score();
        return ind;
    }
};

/// Container for a group of individuals.
const Population = struct {
    pop: [POP_SIZE]Individual,

    /// Initialize a group of individuals.
    fn init() Population {
        var pop: [POP_SIZE]Individual = undefined;
        for (0..POP_SIZE) |i| {
            pop[i] = Individual.init(i);
        }
        return .{ .pop = pop };
    }

    /// Combine the dna of two individuals, creating a new one.
    fn breed(id: usize, a: Individual, b: Individual) Individual {
        // Where to split the two sequences
        const split: usize = rand.uintAtMost(usize, LENGTH);

        // Create a new sequence and copy the splits into it
        var seq: [LENGTH]u8 = undefined;
        @memcpy(seq[0..split], a.dna.seq[0..split]);
        @memcpy(seq[split..LENGTH], b.dna.seq[split..LENGTH]);

        // Evolve the new sequence
        for (0..LENGTH) |i| {
            if (rand.float(f32) < MUT_PROP) seq[i] = rand.intRangeAtMost(u8, 32, 126);
        }

        // Create and return a new individual
        var new = Individual{ .id = id, .dna = .{ .seq = seq, .score = 0.0 } };
        new.score();
        return new;
    }

    /// Select two individuals, breed them to a new one and override the current
    /// population.
    fn nextGeneration(p: *Population) void {
        var new_pop: [POP_SIZE]Individual = undefined;
        for (0..POP_SIZE) |i| {
            var a: Individual = undefined;
            var b: Individual = undefined;
            while (true) {
                a = weightedChoice(p.pop);
                b = weightedChoice(p.pop);
                if (a.id != b.id) break;
            }
            new_pop[i] = Population.breed(i, a, b);
        }
        p.pop = new_pop;
    }

    /// Print the id, the DNA sequence and score of the best individual.
    fn printBest(p: *Population, gen: usize) void {
        var best_score: f32 = 0;
        var index: usize = 0;
        for (p.pop, 0..POP_SIZE) |ind, i| {
            if (ind.dna.score > best_score) {
                best_score = ind.dna.score;
                index = i;
            }
        }
        std.debug.print("{d:<4}: {s}: {d}\n", .{ gen, p.pop[index].dna.seq, p.pop[index].dna.score });
    }

    /// Run nextGeneration n times.
    fn evolve(p: *Population, n: usize) void {
        const skip: usize = 100;
        var i: usize = 0;
        while (i < n) {
            p.nextGeneration();
            if (i % skip == 0) p.printBest(i);
            i += 1;
        }
        p.printBest(n);
    }
};

/// Based on the score of the individuals, select one.
pub fn weightedChoice(
    population: [POP_SIZE]Individual,
) Individual {
    var total_score: f32 = 0;
    for (population) |ind| total_score += ind.dna.score;

    const r: f32 = rand.float(f32) * total_score;

    var current_sum: f32 = 0.0;
    for (population, 0..) |ind, i| {
        current_sum += ind.dna.score;
        if (r < current_sum) return population[i];
    }
    // Select random individual if none of the individuals have any score.
    if (current_sum == 0.0) return population[rand.uintLessThan(usize, POP_SIZE)];
    return population[population.len - 1];
}

pub fn main() !void {
    var pop = Population.init();
    pop.evolve(GENERATIONS);
}
