#!/usr/bin/env node
const assert = require("node:assert/strict")
const fs = require("node:fs")
const vm = require("node:vm")

const context = {}
vm.createContext(context)
vm.runInContext(fs.readFileSync("GameOfLife.js", "utf8"), context)
const Engine = context

function aliveCells(grid) {
  return grid.reduce((total, cell) => total + cell, 0)
}

// A block is a still life.
let grid = Engine.makeGrid(6, 6)
for (const [x, y] of [[2, 2], [3, 2], [2, 3], [3, 3]]) Engine.setCell(grid, 6, x, y, 1)
assert.deepEqual(Engine.step(grid, 6, 6, false), grid)

// A blinker alternates between horizontal and vertical every generation.
grid = Engine.makeGrid(5, 5)
for (const x of [1, 2, 3]) Engine.setCell(grid, 5, x, 2, 1)
let next = Engine.step(grid, 5, 5, false)
assert.equal(next[1 * 5 + 2], 1)
assert.equal(next[2 * 5 + 2], 1)
assert.equal(next[3 * 5 + 2], 1)
assert.equal(aliveCells(next), 3)
assert.deepEqual(Engine.step(next, 5, 5, false), grid)

// Wrapping changes the outcome at an edge.
grid = Engine.makeGrid(3, 3)
for (const [x, y] of [[0, 0], [2, 0], [0, 2]]) Engine.setCell(grid, 3, x, y, 1)
assert.equal(Engine.step(grid, 3, 3, false)[0], 0)
assert.equal(Engine.step(grid, 3, 3, true)[0], 1)

function assertSeedSize(type, width, height) {
  const size = Engine.seedSize(type)
  assert.equal(size.width, width)
  assert.equal(size.height, height)
}

assertSeedSize("glider", 3, 3)
assertSeedSize("acorn", 7, 3)
assertSeedSize("omarchy", 9, 15)
assertSeedSize("pulsar", 13, 13)
assertSeedSize("gun", 36, 9)

// Presets are centred, retain their expected population, and never clip.
grid = Engine.makeGrid(48, 32)
assert.equal(Engine.seed(grid, 48, 32, "glider"), true)
assert.equal(aliveCells(grid), 5)
Engine.clear(grid)
assert.equal(Engine.seed(grid, 48, 32, "acorn"), true)
assert.equal(aliveCells(grid), 7)
Engine.clear(grid)
assert.equal(Engine.seed(grid, 48, 32, "omarchy"), true)
assert.equal(aliveCells(grid), 84)
Engine.clear(grid)
assert.equal(Engine.seed(grid, 48, 32, "pulsar"), true)
assert.equal(aliveCells(grid), 48)
Engine.clear(grid)
assert.equal(Engine.seed(grid, 48, 32, "gun"), true)
assert.equal(aliveCells(grid), 36)
grid = Engine.makeGrid(8, 8)
assert.equal(Engine.seed(grid, 8, 8, "gun"), false)
assert.equal(aliveCells(grid), 0)

console.log("Game of Life engine tests passed")
