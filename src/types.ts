export interface Tile {
  id: string;
  value: number;
  row: number;
  col: number;
  merged?: boolean;
  isNew?: boolean;
}

export type Board = (Tile | null)[][];

export type Direction = 'UP' | 'DOWN' | 'LEFT' | 'RIGHT';

export interface GameRecord {
  id: string;
  date: string;
  score: number;
  highestTile: number;
}
