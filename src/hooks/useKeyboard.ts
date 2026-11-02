import { useEffect } from 'react';
import type { Direction } from '../types';

const KEY_MAP: Record<string, Direction> = {
  ArrowUp: 'UP',
  w: 'UP',
  W: 'UP',
  ArrowDown: 'DOWN',
  s: 'DOWN',
  S: 'DOWN',
  ArrowLeft: 'LEFT',
  a: 'LEFT',
  A: 'LEFT',
  ArrowRight: 'RIGHT',
  d: 'RIGHT',
  D: 'RIGHT',
};

export function useKeyboard(onMove: (direction: Direction) => void, enabled = true): void {
  useEffect(() => {
    if (!enabled) return;

    const handler = (e: KeyboardEvent) => {
      // No interferir con atajos del navegador (Ctrl+S, Cmd+R, etc.)
      if (e.ctrlKey || e.metaKey || e.altKey) return;
      const direction = KEY_MAP[e.key];
      if (!direction) return;
      e.preventDefault();
      onMove(direction);
    };

    window.addEventListener('keydown', handler);
    return () => window.removeEventListener('keydown', handler);
  }, [onMove, enabled]);
}
