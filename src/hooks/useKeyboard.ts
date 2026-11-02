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

interface KeyboardHandlers {
  onMove: (direction: Direction) => void;
  onUndo: () => void;
  onToggleSound: () => void;
}

export function useKeyboard({ onMove, onUndo, onToggleSound }: KeyboardHandlers, enabled = true): void {
  useEffect(() => {
    if (!enabled) return;

    const handler = (e: KeyboardEvent) => {
      // Ctrl/Cmd+Z = deshacer
      if ((e.ctrlKey || e.metaKey) && !e.altKey && (e.key === 'z' || e.key === 'Z')) {
        e.preventDefault();
        onUndo();
        return;
      }
      // No interferir con otros atajos del navegador (Ctrl+S, Cmd+R, etc.)
      if (e.ctrlKey || e.metaKey || e.altKey) return;

      if (e.key === 'u' || e.key === 'U') {
        e.preventDefault();
        onUndo();
        return;
      }
      if (e.key === 'm' || e.key === 'M') {
        e.preventDefault();
        onToggleSound();
        return;
      }

      const direction = KEY_MAP[e.key];
      if (!direction) return;
      e.preventDefault();
      onMove(direction);
    };

    window.addEventListener('keydown', handler);
    return () => window.removeEventListener('keydown', handler);
  }, [onMove, onUndo, onToggleSound, enabled]);
}
