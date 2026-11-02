import type { Tile } from '../types';
import { DaisyPetalSVG, SunflowerSVG } from './FlowerIcons';

const getTileStyle = (value: number, isMerged?: boolean): string => {
  let base: string;
  switch (value) {
    case 2:
      base = 'bg-slate-50 text-slate-800 border-amber-200 shadow-sm';
      break;
    case 4:
      base = 'bg-amber-100 text-amber-900 border-amber-300 shadow-sm';
      break;
    case 8:
      base = 'bg-orange-200 text-orange-950 border-orange-300 shadow-md';
      break;
    case 16:
      base = 'bg-orange-300 text-orange-950 border-orange-400 shadow-md';
      break;
    case 32:
      base = 'bg-orange-400 text-white border-orange-500 shadow-lg';
      break;
    case 64:
      base = 'bg-orange-500 text-white border-orange-600 shadow-lg';
      break;
    case 128:
      base = 'bg-amber-500 text-white border-amber-300 shadow-amber-500/40 shadow-xl';
      break;
    case 256:
      base = 'bg-rose-400 text-white border-rose-300 shadow-rose-400/50 shadow-xl';
      break;
    case 512:
      base = 'bg-rose-500 text-white border-rose-400 shadow-rose-500/60 shadow-xl';
      break;
    case 1024:
      base = 'bg-pink-500 text-white border-pink-300 shadow-pink-500/60 shadow-2xl';
      break;
    case 2048:
      base =
        'bg-gradient-to-r from-amber-400 via-orange-500 to-rose-500 text-white border-amber-200 shadow-orange-500/80 shadow-2xl';
      break;
    default:
      base = 'bg-purple-600 text-white border-purple-300 shadow-2xl';
      break;
  }

  const mergeGlow = isMerged
    ? 'ring-4 ring-amber-300/80 shadow-[0_0_30px_rgba(251,191,36,0.9)] animate-pulse-fast border-amber-200 z-20 scale-105'
    : '';

  return `${base} ${mergeGlow}`;
};

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
