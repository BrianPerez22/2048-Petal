import type { Tile } from '../types';
import { DaisyPetalSVG, SunflowerSVG } from './FlowerIcons';
import { getTileStyle } from '../lib/tileStyles';

export default function TileView({ tile }: { tile: Tile }) {
  return (
    <div
      className="absolute top-3 left-3 w-[calc(25%-0.5625rem)] h-[calc(25%-0.5625rem)] p-0.5 transition-transform duration-200 ease-in-out"
      style={{ transform: `translate(${tile.col * 100}%, ${tile.row * 100}%)` }}
    >
      <div
        className={`w-full h-full rounded-2xl border-2 border-dashed flex flex-col items-center justify-center transform transition-all duration-150 ${getTileStyle(
          tile.value,
          tile.merged
        )} ${tile.isNew ? 'animate-pop-in' : ''}`}
      >
        <span className="text-2xl sm:text-3xl font-black tracking-tight drop-shadow-sm">{tile.value}</span>
        {tile.value >= 128 &&
          (tile.value >= 512 ? (
            <SunflowerSVG className="w-4 h-4 mt-0.5" />
          ) : (
            <DaisyPetalSVG className="w-4 h-4 mt-0.5 text-white" />
          ))}
      </div>
    </div>
  );
}
