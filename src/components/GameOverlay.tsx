import { RotateCcw } from 'lucide-react';
import { SunflowerSVG } from './FlowerIcons';

interface GameOverlayProps {
  gameOver: boolean;
  gameWon: boolean;
  score: number;
  onContinue: () => void;
  onRestart: () => void;
}

export default function GameOverlay({ gameOver, gameWon, score, onContinue, onRestart }: GameOverlayProps) {
  const showContinue = gameWon && !gameOver;

  return (
    <div className="absolute inset-0 bg-slate-950/85 backdrop-blur-md rounded-3xl flex flex-col items-center justify-center p-6 text-center z-30 animate-pop-in border-2 border-dashed border-amber-400/50">
      <SunflowerSVG className="w-16 h-16 animate-bounce mb-3" />
      <h2 className="text-3xl font-black text-amber-300 mb-1">
        {showContinue ? '¡Has ganado!' : '¡Juego Terminado!'}
      </h2>
      <p className="text-slate-300 text-sm mb-4">
        Puntaje final: <span className="font-extrabold text-amber-400">{score}</span>
      </p>

      <div className="flex gap-3">
        {showContinue && (
          <button
            onClick={onContinue}
            className="px-4 py-2.5 bg-slate-800 hover:bg-slate-700 text-slate-200 font-bold rounded-xl border border-dashed border-slate-600 text-sm transition-all pointer-events-auto"
          >
            Continuar
          </button>
        )}
        <button
          onClick={onRestart}
          className="px-5 py-2.5 bg-gradient-to-r from-amber-500 to-orange-500 hover:from-amber-400 hover:to-orange-400 text-white font-bold rounded-xl shadow-lg border border-dashed border-amber-200 text-sm transition-all flex items-center gap-2 pointer-events-auto"
        >
          <RotateCcw className="w-4 h-4" />
          Jugar de nuevo
        </button>
      </div>
    </div>
  );
}
