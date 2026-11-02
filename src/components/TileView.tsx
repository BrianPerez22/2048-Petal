import type { Tile } from '../types';
import { DaisyPetalSVG, SunflowerSVG } from './FlowerIcons';
import { getTileStyle, tileFontSize } from '../lib/tileStyles';

/** Lado de una casilla: (ancho útil − 3 separaciones) / 4. --gap lo define Board.tsx */
const CELL = 'calc((100% - 3 * var(--gap)) / 4)';

/** Desplazamiento de n casillas. En translate(), el 100% es el tamaño de la propia ficha. */
const offset = (n: number) => `calc(${n} * (100% + var(--gap)))`;

export default function TileView({ tile }: { tile: Tile }) {
  return (
    <div
      className="absolute top-0 left-0 transition-transform duration-200 ease-in-out will-change-transform"
      style={{
        width: CELL,
        height: CELL,
        transform: `translate(${offset(tile.col)}, ${offset(tile.row)})`,
      }}
    >
      <div
        className={`w-full h-full rounded-xl sm:rounded-2xl border-2 border-dashed flex flex-col items-center justify-center transform transition-all duration-150 ${getTileStyle(
          tile.value,
          tile.merged
        )} ${tile.isNew ? 'animate-pop-in' : ''}`}
      >
        <span
          className="font-black tracking-tight leading-none drop-shadow-sm"
          style={{ fontSize: tileFontSize(tile.value) }}
        >
          {tile.value}
        </span>
        {tile.value >= 128 &&
          (tile.value >= 512 ? (
            <SunflowerSVG className="w-3 h-3 sm:w-4 sm:h-4 mt-0.5" />
          ) : (
            <DaisyPetalSVG className="w-3 h-3 sm:w-4 sm:h-4 mt-0.5 text-white" />
          ))}
      </div>
    </div>
  );
}
