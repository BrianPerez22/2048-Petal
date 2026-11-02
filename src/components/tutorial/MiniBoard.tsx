import { ArrowDown, ArrowLeft, ArrowRight, ArrowUp } from 'lucide-react';
import { getTileStyle, tileFontSize } from '../../lib/tileStyles';
import type { Direction } from '../../types';

interface MiniBoardProps {
  cells: number[][];
  /** Casillas [fila, columna] que brillan para llamar la atención */
  highlight?: [number, number][];
  /** Movimiento sugerido para esta escena */
  hint?: Direction;
}

const HINT_LABEL: Record<Direction, { text: string; icon: JSX.Element }> = {
  UP: { text: 'Arriba', icon: <ArrowUp className="w-5 h-5" /> },
  DOWN: { text: 'Abajo', icon: <ArrowDown className="w-5 h-5" /> },
  LEFT: { text: 'Izquierda', icon: <ArrowLeft className="w-5 h-5" /> },
  RIGHT: { text: 'Derecha', icon: <ArrowRight className="w-5 h-5" /> },
};

export default function MiniBoard({ cells, highlight = [], hint }: MiniBoardProps) {
  const isHighlighted = (r: number, c: number) => highlight.some(([hr, hc]) => hr === r && hc === c);

  return (
    <div className="w-full flex flex-col items-center gap-4">
      <div
        className="grid grid-cols-4 grid-rows-4 w-full max-w-[420px] aspect-square bg-[#0c0e15] border-2 border-dashed border-amber-500/40 rounded-2xl sm:rounded-3xl shadow-xl [--gap:0.4rem] sm:[--gap:0.6rem]"
        style={{ padding: 'var(--gap)', gap: 'var(--gap)' }}
      >
        {cells.flat().map((value, i) => {
          const r = Math.floor(i / 4);
          const c = i % 4;
          if (value === 0) {
            return (
              <div
                key={i}
                className="rounded-lg sm:rounded-xl bg-slate-800/40 border border-dashed border-slate-700/60"
              />
            );
          }
          return (
            <div
              key={i}
              className={`rounded-lg sm:rounded-xl border-2 border-dashed flex items-center justify-center font-black tracking-tight leading-none ${getTileStyle(
                value
              )} ${isHighlighted(r, c) ? 'ring-2 ring-amber-300 animate-pulse' : ''}`}
              style={{ fontSize: tileFontSize(value) }}
            >
              {value}
            </div>
          );
        })}
      </div>

      {hint && (
        <span className="inline-flex items-center gap-2 px-4 py-1.5 rounded-full border border-dashed border-amber-400/50 bg-amber-500/10 text-amber-300 text-sm sm:text-base font-bold">
          Mueve {HINT_LABEL[hint].text}
          {HINT_LABEL[hint].icon}
        </span>
      )}
    </div>
  );
}
