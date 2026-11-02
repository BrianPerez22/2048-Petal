import type { Direction } from '../../types';

export interface Scene {
  text: string;
  cells: number[][];
  highlight?: [number, number][];
  hint?: Direction;
}

/** Escenas de mini-tablero: cuentan la estrategia de la esquina paso a paso. */
export const SCENES: Scene[] = [
  {
    text: 'Junta las fichas iguales para que se fusionen en una más grande.',
    cells: [
      [0, 0, 0, 0],
      [0, 0, 0, 0],
      [0, 0, 2, 0],
      [0, 0, 2, 4],
    ],
    highlight: [[2, 2], [3, 2]],
    hint: 'DOWN',
  },
  {
    text: 'Mantén tus fichas grandes en la fila inferior.',
    cells: [
      [0, 0, 0, 0],
      [0, 0, 0, 2],
      [0, 0, 4, 0],
      [64, 32, 16, 8],
    ],
    highlight: [[3, 0], [3, 1], [3, 2], [3, 3]],
  },
  {
    text: 'Apila las más grandes en una esquina y no la sueltes.',
    cells: [
      [0, 0, 0, 0],
      [0, 0, 2, 0],
      [4, 8, 0, 2],
      [256, 128, 64, 32],
    ],
    highlight: [[3, 0]],
  },
  {
    text: 'Llena la fila inferior sin mover hacia arriba.',
    cells: [
      [0, 0, 0, 0],
      [0, 0, 0, 2],
      [0, 0, 4, 2],
      [1024, 512, 256, 128],
    ],
    highlight: [[3, 0], [3, 1], [3, 2], [3, 3]],
  },
  {
    text: 'Ahora la siguiente fila, en sentido contrario, sin romper la de abajo.',
    cells: [
      [0, 0, 0, 0],
      [0, 0, 0, 2],
      [8, 16, 32, 64],
      [1024, 512, 256, 128],
    ],
    highlight: [[2, 0], [2, 1], [2, 2], [2, 3]],
  },
  {
    text: 'Acumula las fichas pequeñas necesarias para completar otra fila.',
    cells: [
      [0, 0, 0, 2],
      [4, 2, 0, 0],
      [8, 16, 32, 64],
      [1024, 512, 256, 128],
    ],
    highlight: [[1, 0], [1, 1]],
  },
  {
    text: 'Y estas serán todas las fichas que necesitarás.',
    cells: [
      [0, 0, 2, 2],
      [4, 2, 2, 0],
      [8, 16, 32, 64],
      [1024, 512, 256, 128],
    ],
    highlight: [[0, 2], [0, 3], [1, 1], [1, 2]],
  },
  {
    text: '¡Júntalas para hacer florecer el 2048! ⭐',
    cells: [
      [0, 0, 0, 0],
      [0, 0, 0, 0],
      [0, 0, 0, 0],
      [1024, 1024, 0, 0],
    ],
    highlight: [[3, 0], [3, 1]],
    hint: 'LEFT',
  },
  {
    text: 'Pero ahí no acaba el juego: sigue hasta que el tablero ya no aguante más 🔥',
    cells: [
      [2, 4, 2, 4],
      [4, 8, 16, 2],
      [2048, 1024, 512, 256],
      [8, 16, 32, 64],
    ],
    highlight: [[2, 0]],
  },
];
