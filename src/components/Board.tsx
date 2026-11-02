import { useMemo } from 'react';
import type { CSSProperties } from 'react';
import type { Board as BoardType, Direction } from '../types';
import { boardToTiles, GRID_SIZE } from '../game/logic';
import { useSwipe } from '../hooks/useSwipe';
import TileView from './TileView';
import GameOverlay from './GameOverlay';

interface BoardProps {
  board: BoardType;
  score: number;
  gameOver: boolean;
  gameWon: boolean;
  onSwipe: (direction: Direction) => void;
  onContinue: () => void;
  onRestart: () => void;
}

/**
 * Las celdas del fondo y las fichas viven en dos capas que ocupan EXACTAMENTE
 * la misma caja (`inset: var(--gap)`), y ambas leen la misma variable --gap.
 * Así el cálculo de cada ficha coincide con su casilla en cualquier navegador.
 */
const LAYER: CSSProperties = { inset: 'var(--gap)' };

export default function Board({
  board,
  score,
  gameOver,
  gameWon,
  onSwipe,
  onContinue,
  onRestart,
}: BoardProps) {
  const tiles = useMemo(() => boardToTiles(board), [board]);
  const swipe = useSwipe(onSwipe);

  return (
    <div className="lg:col-span-6 flex flex-col items-center justify-center w-full order-1 lg:order-2">
      <div
        {...swipe}
        className="relative isolate w-full max-w-md aspect-square bg-[#0c0e15] border-2 border-dashed border-amber-500/40 rounded-3xl shadow-2xl overflow-hidden touch-none [--gap:0.5rem] sm:[--gap:0.75rem]"
      >
        <div className="absolute grid grid-cols-4 grid-rows-4" style={{ ...LAYER, gap: 'var(--gap)' }}>
          {Array.from({ length: GRID_SIZE * GRID_SIZE }).map((_, idx) => (
            <div
              key={idx}
              className="bg-slate-800/40 border border-dashed border-slate-700/60 rounded-xl sm:rounded-2xl"
            />
          ))}
        </div>

        <div className="absolute pointer-events-none" style={LAYER}>
          {tiles.map((tile) => (
            <TileView key={tile.id} tile={tile} />
          ))}
        </div>

        {(gameOver || gameWon) && (
          <GameOverlay
            gameOver={gameOver}
            gameWon={gameWon}
            score={score}
            onContinue={onContinue}
            onRestart={onRestart}
          />
        )}
      </div>
    </div>
  );
}
