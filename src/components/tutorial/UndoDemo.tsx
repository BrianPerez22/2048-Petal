import { useState } from 'react';
import { DaisyPetalSVG } from '../FlowerIcons';

const TOTAL = 10;

/** Slider de práctica: no afecta la partida, solo enseña cómo funciona. */
export default function UndoDemo() {
  const [value, setValue] = useState(6);

  return (
    <div className="w-full max-w-sm mx-auto bg-slate-950/60 border border-dashed border-amber-500/30 rounded-2xl p-4 flex flex-col gap-3">
      <div className="flex items-center justify-between text-sm">
        <label htmlFor="undo-demo" className="text-slate-300 font-semibold">
          Max Deshacer:
        </label>
        <span className="text-2xl font-black text-amber-300 tabular-nums">{value}</span>
      </div>

      <input
        id="undo-demo"
        type="range"
        min={0}
        max={TOTAL}
        value={value}
        onChange={(e) => setValue(parseInt(e.target.value, 10))}
        className="w-full accent-amber-400 cursor-pointer h-1.5"
      />

      <div className="flex justify-between gap-1" aria-hidden="true">
        {Array.from({ length: TOTAL }).map((_, i) => (
          <DaisyPetalSVG
            key={i}
            className={`w-6 h-6 text-amber-50 transition-all duration-200 ${
              i < value ? 'opacity-100 scale-100' : 'opacity-20 scale-75 grayscale'
            }`}
          />
        ))}
      </div>

      <p className="text-[11px] text-slate-500 italic text-center">
        Cada margarita encendida es un movimiento que podrás deshacer.
      </p>
    </div>
  );
}
