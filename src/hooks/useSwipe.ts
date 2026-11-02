import { useCallback, useRef } from 'react';
import type { TouchEvent } from 'react';
import type { Direction } from '../types';

const SWIPE_THRESHOLD = 30;

export function useSwipe(onSwipe: (direction: Direction) => void) {
  const start = useRef<{ x: number; y: number } | null>(null);

  const onTouchStart = useCallback((e: TouchEvent) => {
    start.current = { x: e.touches[0].clientX, y: e.touches[0].clientY };
  }, []);

  const onTouchEnd = useCallback(
    (e: TouchEvent) => {
      if (!start.current) return;
      const dx = e.changedTouches[0].clientX - start.current.x;
      const dy = e.changedTouches[0].clientY - start.current.y;
      start.current = null;

      if (Math.abs(dx) > Math.abs(dy)) {
        if (Math.abs(dx) > SWIPE_THRESHOLD) onSwipe(dx > 0 ? 'RIGHT' : 'LEFT');
      } else if (Math.abs(dy) > SWIPE_THRESHOLD) {
        onSwipe(dy > 0 ? 'DOWN' : 'UP');
      }
    },
    [onSwipe]
  );

  return { onTouchStart, onTouchEnd };
}
