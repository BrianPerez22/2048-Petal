import { ArrowDown, ArrowLeft, ArrowRight, ArrowUp } from 'lucide-react';
import { getTileStyle } from '../../lib/tileStyles';
import type { Direction } from '../../types';

interface MiniBoardProps {
  cells: number[][];
  /** Casillas [fila, columna] que brillan para llamar la atención */
  highlight?: [number, number][];
  /** Movimiento sugerido para esta escena */
  hint?: Direction;
}

const HINT_LABEL: Record<Direction, { text: string; icon: JSX.Element }> = {
  UP: { text: 'Arriba', icon: <ArrowUp className="w-4 h-4" /> },
  DOWN: { text: 'Abajo', icon: <ArrowDown className="w-4 h-4" /> },
  LEFT: { text: 'Izquierda', icon: <ArrowLeft className="w-4 h-4" /> },
  RIGHT: { text: 'Derecha', icon: <ArrowRight className="w-4 h-4" /> },
};

const textSize = (v: number) => (v < 100 ? 'text-xl' : v < 1000 ? 'text-lg' : 'text-base');

export default function MiniBoard({ cells, highlight = [], hint }: MiniBoardProps) {
  const isHighlighted = (r: number, c: number) => highlight.some(([hr, hc]) => hr === r && hc === c);

  return (
    <div className="flex flex-col items-center gap-3">
      <div className="grid grid-cols-4 grid-rows-4 gap-2 w-full max-w-[320px] aspect-square p-2.5 bg-[#0c0e15] border-2 border-dashed border-amber-500/40 rounded-2xl shadow-xl">
        {cells.flat().map((value, i) => {
          const r = Math.floor(i / 4);
          const c = i % 4;
          if (value === 0) {
            return (
              <div key={i} className="rounded-xl bg-slate-800/40 border border-dashed border-slate-700/60" />
            );
          }
          return (
            <div
              key={i}
              className={`rounded-xl border border-dashed flex items-center justify-center font-black tracking-tight ${textSize(
                value
              )} ${getTileStyle(value)} ${
                isHighlighted(r, c) ? 'ring-2 ring-amber-300 animate-pulse' : ''
              }`}
            >
              {value}
            </div>
          );
        })}
      </div>

      {hint && (
        <span className="inline-flex items-center gap-1.5 px-3 py-1 rounded-full border border-dashed border-amber-400/50 bg-amber-500/10 text-amber-300 text-xs font-bold">
          Mueve {HINT_LABEL[hint].text}
          {HINT_LABEL[hint].icon}
        </span>
      )}
    </div>
  );
}
