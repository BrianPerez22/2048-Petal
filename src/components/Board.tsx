import { useMemo } from 'react';
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
        className="relative w-full max-w-md aspect-square bg-[#0c0e15] border-2 border-dashed border-amber-500/40 rounded-3xl p-3 shadow-2xl flex flex-col justify-between overflow-hidden touch-none"
      >
        <div className="grid grid-cols-4 grid-rows-4 gap-3 w-full h-full">
          {Array.from({ length: GRID_SIZE * GRID_SIZE }).map((_, idx) => (
            <div key={idx} className="bg-slate-800/40 border border-dashed border-slate-700/60 rounded-2xl" />
          ))}
        </div>

        <div className="absolute inset-0 p-3 pointer-events-none">
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
