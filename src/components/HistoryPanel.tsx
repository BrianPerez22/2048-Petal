import { Award, History, Trophy } from 'lucide-react';
import type { GameRecord } from '../types';

interface HistoryPanelProps {
  records: GameRecord[];
  bestScore: number;
}

export default function HistoryPanel({ records, bestScore }: HistoryPanelProps) {
  return (
    <aside className="lg:col-span-3 w-full bg-slate-900/80 border border-dashed border-slate-700/80 rounded-3xl p-4 shadow-xl backdrop-blur-md flex flex-col justify-between h-full order-3">
      <div>
        <div className="flex items-center justify-between border-b border-dashed border-slate-800 pb-3 mb-3">
          <h3 className="font-bold text-slate-200 flex items-center gap-2 text-sm">
            <History className="w-4 h-4 text-amber-400" />
            Historial de Partidas
          </h3>
          <Award className="w-4 h-4 text-orange-400" />
        </div>

        <div className="flex flex-col gap-2.5 max-h-[280px] lg:max-h-[340px] overflow-y-auto pr-1 custom-scrollbar">
          {records.length === 0 ? (
            <div className="text-center py-8 text-slate-500 text-xs border border-dashed border-slate-800 rounded-2xl">
              No hay partidas jugadas aún.
            </div>
          ) : (
            records.map((rec) => (
              <div
                key={rec.id}
                className="bg-slate-800/60 border border-dashed border-slate-700/60 hover:border-amber-500/40 rounded-2xl p-2.5 flex items-center justify-between transition-all"
              >
                <div className="flex flex-col">
                  <span className="text-[10px] text-slate-400">{rec.date}</span>
                  <span className="text-sm font-black text-amber-300">{rec.score} pts</span>
                </div>
                <div className="flex items-center gap-1 bg-amber-500/10 px-2 py-0.5 rounded-xl border border-dashed border-amber-500/30">
                  <span className="text-xs font-bold text-amber-400">Ficha {rec.highestTile}</span>
                </div>
              </div>
            ))
          )}
        </div>
      </div>

      <div className="mt-4 pt-3 border-t border-dashed border-slate-800 flex items-center justify-between text-xs text-slate-400">
        <span className="flex items-center gap-1">
          <Trophy className="w-3.5 h-3.5 text-amber-400" />
          Récord Personal:
        </span>
        <span className="font-bold text-amber-300">{bestScore} pts</span>
      </div>
    </aside>
  );
}
