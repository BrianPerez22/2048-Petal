import { BookOpen, Play, RotateCcw, Settings } from 'lucide-react';
import { DaisyPetalSVG, SunflowerSVG } from './FlowerIcons';
import { MAX_UNDOS_LIMIT } from '../game/reducer';

interface ControlsPanelProps {
  canUndo: boolean;
  undosRemaining: number;
  maxUndos: number;
  undoLimitLocked: boolean;
  onUndo: () => void;
  onRestart: () => void;
  onOpenTutorial: () => void;
  onChangeMaxUndos: (value: number) => void;
}

export default function ControlsPanel({
  canUndo,
  undosRemaining,
  maxUndos,
  undoLimitLocked,
  onUndo,
  onRestart,
  onOpenTutorial,
  onChangeMaxUndos,
}: ControlsPanelProps) {
  return (
    <div className="lg:col-span-3 flex flex-col gap-4 w-full order-2 lg:order-1">
      <div className="bg-slate-900/80 border border-dashed border-amber-500/30 rounded-3xl p-4 backdrop-blur-md shadow-xl flex flex-col gap-3">
        <h3 className="font-bold text-slate-200 text-sm flex items-center gap-2 border-b border-dashed border-slate-800 pb-2">
          <Settings className="w-4 h-4 text-amber-400" />
          Controles del Juego
        </h3>

        <button
          onClick={onUndo}
          disabled={!canUndo}
          className="w-full py-2.5 px-3 bg-gradient-to-r from-amber-500 to-orange-500 hover:from-amber-400 hover:to-orange-400 disabled:from-slate-800 disabled:to-slate-800 disabled:opacity-40 disabled:cursor-not-allowed text-white font-bold rounded-xl shadow-md border border-dashed border-amber-300/40 flex items-center justify-center gap-2 transition-all active:scale-95 text-sm"
        >
          <RotateCcw className="w-4 h-4" />
          Deshacer ({undosRemaining})
        </button>

        <button
          onClick={onRestart}
          className="w-full py-2.5 px-4 bg-slate-800 hover:bg-slate-700 text-slate-200 font-bold rounded-xl border border-dashed border-slate-600 flex items-center justify-center gap-1.5 transition-all text-sm active:scale-95 shadow-md"
        >
          <Play className="w-4 h-4 text-amber-400 fill-amber-400" />
          Reiniciar Partida
        </button>

        <button
          onClick={onOpenTutorial}
          className="w-full py-2 px-3 bg-slate-800/60 hover:bg-slate-700/60 text-amber-300 font-medium rounded-xl border border-dashed border-amber-500/30 flex items-center justify-center gap-1.5 transition-all text-xs active:scale-95"
        >
          <BookOpen className="w-3.5 h-3.5" />
          Ver Tutorial
        </button>

        <div className="flex flex-col gap-1.5 border-t border-dashed border-slate-800 pt-3 mt-1">
          <div className="flex justify-between items-center text-xs">
            <span className="text-slate-400 flex items-center gap-1">Max Deshacer:</span>
            <span className={`font-bold ${undoLimitLocked ? 'text-slate-500' : 'text-amber-300'}`}>
              {maxUndos} {undoLimitLocked && '(Bloqueado)'}
            </span>
          </div>
          <input
            type="range"
            min={0}
            max={MAX_UNDOS_LIMIT}
            value={maxUndos}
            disabled={undoLimitLocked}
            onChange={(e) => onChangeMaxUndos(parseInt(e.target.value, 10))}
            className="w-full accent-amber-400 bg-slate-800 rounded-lg cursor-pointer disabled:opacity-40 disabled:cursor-not-allowed h-1.5"
            aria-label="Máximo de deshacer"
          />
          <p className="text-[10px] text-slate-500 italic mt-0.5">
            Setea los movimientos antes del primer movimiento.
          </p>
        </div>
      </div>

      <div className="bg-slate-900/60 border border-dashed border-slate-800 rounded-2xl p-3 backdrop-blur-md hidden lg:flex flex-col gap-2 text-xs text-slate-400">
        <div className="flex items-center gap-2 text-amber-300 font-medium">
          <DaisyPetalSVG className="w-4 h-4 text-white" />
          <SunflowerSVG className="w-4 h-4" />
          <span>Colección Floral</span>
        </div>
        <p className="leading-relaxed text-[11px]">
          Combina fichas iguales para hacer florecer margaritas y girasoles dorados.
        </p>
      </div>
    </div>
  );
}
