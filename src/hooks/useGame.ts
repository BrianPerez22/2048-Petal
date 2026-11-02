import { useCallback, useEffect, useReducer } from 'react';
import { createInitialState, gameReducer } from '../game/reducer';
import { playBubbleSound } from '../lib/audio';
import { saveBestScore, saveRecords } from '../lib/storage';
import type { Direction } from '../types';

export function useGame() {
  const [state, dispatch] = useReducer(gameReducer, undefined, createInitialState);

  // Persistencia
  useEffect(() => {
    saveBestScore(state.bestScore);
  }, [state.bestScore]);

  useEffect(() => {
    saveRecords(state.records);
  }, [state.records]);

  // Sonido: se dispara una vez por cada evento (seq) emitido por el reducer
  useEffect(() => {
    if (!state.sound || !state.soundEnabled) return;
    playBubbleSound(state.sound.kind === 'merge');
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [state.sound?.seq]);

  const move = useCallback((direction: Direction) => dispatch({ type: 'MOVE', direction }), []);
  const undo = useCallback(() => dispatch({ type: 'UNDO' }), []);
  const newGame = useCallback(() => dispatch({ type: 'NEW_GAME' }), []);
  const setMaxUndos = useCallback((value: number) => dispatch({ type: 'SET_MAX_UNDOS', value }), []);
  const toggleSound = useCallback(() => dispatch({ type: 'TOGGLE_SOUND' }), []);
  const dismissWin = useCallback(() => dispatch({ type: 'DISMISS_WIN' }), []);

  return { state, move, undo, newGame, setMaxUndos, toggleSound, dismissWin };
}
