import type { Board, Direction, GameRecord } from '../types';
import {
  addRandomTile,
  cloneBoard,
  createInitialBoard,
  getHighestTile,
  isGameOver,
  moveBoard,
} from './logic';
import { loadBestScore, loadRecords } from '../lib/storage';

export const MAX_UNDOS_LIMIT = 10;
const MAX_RECORDS = 15;

interface Snapshot {
  board: Board;
  score: number;
  gameOver: boolean;
  won: boolean;
}

export interface SoundEvent {
  kind: 'move' | 'merge' | 'undo';
  seq: number;
}

export interface GameState {
  board: Board;
  score: number;
  bestScore: number;
  maxUndos: number;
  undosRemaining: number;
  undoLimitLocked: boolean;
  soundEnabled: boolean;
  gameOver: boolean;
  gameWon: boolean;
  records: GameRecord[];
  undoStack: Snapshot[];
  sound: SoundEvent | null;
}

export type GameAction =
  | { type: 'MOVE'; direction: Direction }
  | { type: 'UNDO' }
  | { type: 'NEW_GAME' }
  | { type: 'SET_MAX_UNDOS'; value: number }
  | { type: 'TOGGLE_SOUND' }
  | { type: 'DISMISS_WIN' };

export const createInitialState = (): GameState => ({
  board: createInitialBoard(),
  score: 0,
  bestScore: loadBestScore(),
  maxUndos: MAX_UNDOS_LIMIT,
  undosRemaining: MAX_UNDOS_LIMIT,
  undoLimitLocked: false,
  soundEnabled: true,
  gameOver: false,
  gameWon: false,
  records: loadRecords(),
  undoStack: [],
  sound: null,
});

const nextSound = (state: GameState, kind: SoundEvent['kind']): SoundEvent => ({
  kind,
  seq: (state.sound?.seq ?? 0) + 1,
});

const makeRecord = (score: number, board: Board): GameRecord => ({
  id: `rec-${Date.now()}`,
  date: new Date().toLocaleDateString('es-ES', {
    day: '2-digit',
    month: '2-digit',
    hour: '2-digit',
    minute: '2-digit',
  }),
  score,
  highestTile: getHighestTile(board),
});

export function gameReducer(state: GameState, action: GameAction): GameState {
  switch (action.type) {
    case 'MOVE': {
      if (state.gameOver) return state;

      const result = moveBoard(state.board, action.direction);
      if (!result.moved) return state;

      const board = addRandomTile(result.board);
      const score = state.score + result.scoreGained;
      const gameOver = isGameOver(board);

      return {
        ...state,
        board,
        score,
        bestScore: Math.max(state.bestScore, score),
        undoLimitLocked: true,
        gameOver,
        gameWon: state.gameWon || result.reachedWin,
        records: gameOver
          ? [makeRecord(score, board), ...state.records].slice(0, MAX_RECORDS)
          : state.records,
        undoStack: [
          ...state.undoStack,
          {
            board: cloneBoard(state.board, true),
            score: state.score,
            gameOver: state.gameOver,
            won: state.gameWon,
          },
        ],
        sound: nextSound(state, result.merged ? 'merge' : 'move'),
      };
    }

    case 'UNDO': {
      if (state.undoStack.length === 0 || state.undosRemaining <= 0 || state.gameOver) return state;
      const previous = state.undoStack[state.undoStack.length - 1];
      return {
        ...state,
        board: previous.board,
        score: previous.score,
        gameOver: previous.gameOver,
        gameWon: previous.won,
        undoStack: state.undoStack.slice(0, -1),
        undosRemaining: state.undosRemaining - 1,
        sound: nextSound(state, 'undo'),
      };
    }

    case 'NEW_GAME':
      return {
        ...state,
        board: createInitialBoard(),
        score: 0,
        gameOver: false,
        gameWon: false,
        undoStack: [],
        undosRemaining: state.maxUndos,
        undoLimitLocked: false,
      };

    case 'SET_MAX_UNDOS':
      if (state.undoLimitLocked) return state;
      return { ...state, maxUndos: action.value, undosRemaining: action.value };

    case 'TOGGLE_SOUND':
      return { ...state, soundEnabled: !state.soundEnabled };

    case 'DISMISS_WIN':
      return { ...state, gameWon: false };

    default:
      return state;
  }
}
