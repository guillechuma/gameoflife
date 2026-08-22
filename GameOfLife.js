function makeGrid(cols, rows) {
  var g = []
  for (var i = 0; i < cols * rows; i++) g.push(0)
  return g
}

function clear(grid) {
  for (var i = 0; i < grid.length; i++) grid[i] = 0
}

function randomize(grid, cols, rows, density) {
  for (var i = 0; i < grid.length; i++) grid[i] = Math.random() < density ? 1 : 0
}

function setCell(grid, cols, x, y, v) {
  if (x >= 0 && y >= 0 && x < cols && y < grid.length / cols) grid[y * cols + x] = v
}

function step(grid, cols, rows, wrap) {
  var next = []
  for (var y = 0; y < rows; y++) {
    for (var x = 0; x < cols; x++) {
      var n = 0
      for (var dy = -1; dy <= 1; dy++) {
        for (var dx = -1; dx <= 1; dx++) {
          if (dx === 0 && dy === 0) continue
          var nx = x + dx
          var ny = y + dy
          if (wrap) {
            nx = (nx + cols) % cols
            ny = (ny + rows) % rows
          } else if (nx < 0 || ny < 0 || nx >= cols || ny >= rows) {
            continue
          }
          n += grid[ny * cols + nx]
        }
      }
      var alive = grid[y * cols + x]
      next.push((alive && (n === 2 || n === 3)) || (!alive && n === 3) ? 1 : 0)
    }
  }
  return next
}

function seed(grid, cols, rows, type) {
  if (type === "glider") {
    var g = [[1, 0], [2, 1], [0, 2], [1, 2], [2, 2]]
    var ox = Math.floor(cols / 2 - 2)
    var oy = Math.floor(rows / 2 - 2)
    for (var i = 0; i < g.length; i++) setCell(grid, cols, ox + g[i][0], oy + g[i][1], 1)
  } else if (type === "pulsar") {
    var p = [
      [2, 0], [3, 0], [4, 0], [8, 0], [9, 0], [10, 0],
      [0, 2], [5, 2], [7, 2], [12, 2],
      [0, 3], [5, 3], [7, 3], [12, 3],
      [0, 4], [5, 4], [7, 4], [12, 4],
      [2, 5], [3, 5], [4, 5], [8, 5], [9, 5], [10, 5],
      [2, 7], [3, 7], [4, 7], [8, 7], [9, 7], [10, 7],
      [0, 8], [5, 8], [7, 8], [12, 8],
      [0, 9], [5, 9], [7, 9], [12, 9],
      [0, 10], [5, 10], [7, 10], [12, 10],
      [2, 12], [3, 12], [4, 12], [8, 12], [9, 12], [10, 12]
    ]
    var px = Math.floor(cols / 2 - 6)
    var py = Math.floor(rows / 2 - 6)
    for (var j = 0; j < p.length; j++) setCell(grid, cols, px + p[j][0], py + p[j][1], 1)
  } else if (type === "gun") {
    var gun = [
      [0, 4], [0, 5], [1, 4], [1, 5],
      [10, 4], [10, 5], [10, 6], [11, 3], [11, 7], [12, 2], [12, 8], [13, 2], [13, 8],
      [14, 5], [15, 3], [15, 7], [16, 4], [16, 5], [16, 6], [17, 5],
      [20, 2], [20, 3], [20, 4], [21, 2], [21, 3], [21, 4], [22, 1], [22, 5],
      [24, 0], [24, 1], [24, 5], [24, 6],
      [34, 2], [34, 3], [35, 2], [35, 3]
    ]
    for (var k = 0; k < gun.length; k++) setCell(grid, cols, 1 + gun[k][0], 1 + gun[k][1], 1)
  }
}
