import { HelpCircle, Sparkles, Volume2, VolumeX } from 'lucide-react';
import { DaisyPetalSVG } from './FlowerIcons';

interface HeaderProps {
  score: number;
  bestScore: number;
  soundEnabled: boolean;
  onToggleSound: () => void;
  onOpenTutorial: () => void;
}

export default function Header({
  score,
  bestScore,
  soundEnabled,
  onToggleSound,
  onOpenTutorial,
}: HeaderProps) {
  return (
    <header className="relative z-10 w-full max-w-6xl mx-auto px-4 pt-5 pb-2 flex flex-col sm:flex-row items-center justify-between gap-4 border-b border-dashed border-slate-700/60">
      <div className="flex items-center gap-3">
        <div className="relative p-2 bg-gradient-to-br from-amber-400 to-orange-500 rounded-2xl shadow-lg border-2 border-dashed border-amber-200 flex items-center justify-center">
          <DaisyPetalSVG className="w-8 h-8 text-white animate-spin-slow" />
        </div>
        <div>
          <h1 className="text-3xl font-extrabold tracking-tight bg-gradient-to-r from-amber-300 via-yellow-400 to-amber-200 bg-clip-text text-transparent">
            2048 Petal
          </h1>
          <p className="text-xs text-slate-400 flex items-center gap-1 font-medium">
            <span>Pétalos &amp; Girasoles</span>
            <Sparkles className="w-3.5 h-3.5 text-amber-400 inline" />
          </p>
        </div>
      </div>

      <div className="flex items-center gap-3">
        <div className="bg-slate-900/80 border border-dashed border-amber-500/40 rounded-2xl px-4 py-2 text-center min-w-[110px] shadow-inner backdrop-blur-md">
          <span className="text-[10px] uppercase font-bold tracking-widest text-amber-400 block">Puntaje</span>
          <span className="text-xl font-black text-amber-200">{score}</span>
        </div>

        <div className="bg-slate-900/80 border border-dashed border-orange-500/40 rounded-2xl px-4 py-2 text-center min-w-[110px] shadow-inner backdrop-blur-md">
          <span className="text-[10px] uppercase font-bold tracking-widest text-orange-400 block">Mejor</span>
          <span className="text-xl font-black text-orange-200">{bestScore}</span>
        </div>

        <button
          onClick={onOpenTutorial}
          className="p-3 bg-slate-800/80 hover:bg-slate-700 border border-dashed border-slate-600 rounded-2xl transition-all shadow-md text-amber-300 active:scale-95"
          title="Cómo jugar (Tutorial)"
          aria-label="Abrir tutorial"
        >
          <HelpCircle className="w-5 h-5" />
        </button>

        <button
          onClick={onToggleSound}
          className="p-3 bg-slate-800/80 hover:bg-slate-700 border border-dashed border-slate-600 rounded-2xl transition-all shadow-md text-amber-300 active:scale-95"
          title={soundEnabled ? 'Silenciar sonidos' : 'Activar sonidos'}
          aria-label={soundEnabled ? 'Silenciar sonidos' : 'Activar sonidos'}
        >
          {soundEnabled ? <Volume2 className="w-5 h-5" /> : <VolumeX className="w-5 h-5 text-slate-500" />}
        </button>
      </div>
    </header>
  );
}
