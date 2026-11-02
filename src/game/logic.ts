import type { Board, Direction, Tile } from '../types';

export const GRID_SIZE = 4;
export const WIN_VALUE = 2048;

export const createEmptyBoard = (): Board =>
  Array.from({ length: GRID_SIZE }, () => Array<Tile | null>(GRID_SIZE).fill(null));

/** Copia el tablero. Con resetFlags=true limpia las marcas de animación (merged / isNew). */
export const cloneBoard = (board: Board, resetFlags = false): Board =>
  board.map((row) =>
    row.map((cell) =>
      cell ? (resetFlags ? { ...cell, merged: false, isNew: false } : { ...cell }) : null
    )
  );

export const addRandomTile = (board: Board): Board => {
  const emptyCells: { r: number; c: number }[] = [];
  for (let r = 0; r < GRID_SIZE; r++) {
    for (let c = 0; c < GRID_SIZE; c++) {
      if (!board[r][c]) emptyCells.push({ r, c });
    }
  }
  if (emptyCells.length === 0) return board;

  const { r, c } = emptyCells[Math.floor(Math.random() * emptyCells.length)];
  const next = cloneBoard(board);
  next[r][c] = {
    id: `tile-${Date.now()}-${Math.random()}`,
    value: Math.random() < 0.9 ? 2 : 4,
    row: r,
    col: c,
    isNew: true,
  };
  return next;
};

export const createInitialBoard = (): Board => addRandomTile(addRandomTile(createEmptyBoard()));

export const boardToTiles = (board: Board): Tile[] => board.flat().filter((t): t is Tile => t !== null);

export const getHighestTile = (board: Board): number =>
  boardToTiles(board).reduce((max, t) => Math.max(max, t.value), 0);

export const isGameOver = (board: Board): boolean => {
  for (let r = 0; r < GRID_SIZE; r++) {
    for (let c = 0; c < GRID_SIZE; c++) {
      if (!board[r][c]) return false;
    }
  }
  for (let r = 0; r < GRID_SIZE; r++) {
    for (let c = 0; c < GRID_SIZE; c++) {
      const current = board[r][c]?.value;
      if (c < GRID_SIZE - 1 && board[r][c + 1]?.value === current) return false;
      if (r < GRID_SIZE - 1 && board[r + 1][c]?.value === current) return false;
    }
  }
  return true;
};

export interface MoveResult {
  board: Board;
  moved: boolean;
  scoreGained: number;
  merged: boolean;
  reachedWin: boolean;
}

const VECTORS: Record<Direction, { r: number; c: number }> = {
  UP: { r: -1, c: 0 },
  DOWN: { r: 1, c: 0 },
  LEFT: { r: 0, c: -1 },
  RIGHT: { r: 0, c: 1 },
};

/** Desliza y fusiona las fichas. Función pura: no agrega la ficha nueva ni toca el estado. */
export const moveBoard = (board: Board, direction: Direction): MoveResult => {
  const vec = VECTORS[direction];
  const rIndices = direction === 'DOWN' ? [3, 2, 1, 0] : [0, 1, 2, 3];
  const cIndices = direction === 'RIGHT' ? [3, 2, 1, 0] : [0, 1, 2, 3];

  const next = cloneBoard(board, true);
  let moved = false;
  let merged = false;
  let reachedWin = false;
  let scoreGained = 0;

  for (const r of rIndices) {
    for (const c of cIndices) {
      const current = next[r][c];
      if (!current) continue;

      let targetR = r;
      let targetC = c;

      while (true) {
        const nextR = targetR + vec.r;
        const nextC = targetC + vec.c;
        if (nextR < 0 || nextR >= GRID_SIZE || nextC < 0 || nextC >= GRID_SIZE) break;

        const neighbor = next[nextR][nextC];
        if (!neighbor) {
          targetR = nextR;
          targetC = nextC;
        } else if (neighbor.value === current.value && !neighbor.merged) {
          targetR = nextR;
          targetC = nextC;
          break;
        } else {
          break;
        }
      }

      if (targetR === r && targetC === c) continue;
      moved = true;

      const target = next[targetR][targetC];
      if (target && target.value === current.value && !target.merged) {
        const value = current.value * 2;
        scoreGained += value;
        merged = true;
        if (value === WIN_VALUE) reachedWin = true;
        next[targetR][targetC] = { id: current.id, value, row: targetR, col: targetC, merged: true };
      } else {
        next[targetR][targetC] = { ...current, row: targetR, col: targetC };
      }
      next[r][c] = null;
    }
  }

  return { board: next, moved, scoreGained, merged, reachedWin };
};
