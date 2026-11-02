import { Sparkles } from 'lucide-react';
import { DaisyPetalSVG } from './FlowerIcons';

export default function Brand({ subtitle = 'Pétalos & Girasoles' }: { subtitle?: string }) {
  return (
    <div className="flex items-center gap-3">
      <div className="relative p-2 bg-gradient-to-br from-amber-400 to-orange-500 rounded-2xl shadow-lg border-2 border-dashed border-amber-200 flex items-center justify-center">
        <DaisyPetalSVG className="w-8 h-8 text-white animate-spin-slow" />
      </div>
      <div>
        <h1 className="text-3xl font-extrabold tracking-tight bg-gradient-to-r from-amber-300 via-yellow-400 to-amber-200 bg-clip-text text-transparent">
          2048 Petal
        </h1>
        <p className="text-xs text-slate-400 flex items-center gap-1 font-medium">
          <span>{subtitle}</span>
          <Sparkles className="w-3.5 h-3.5 text-amber-400 inline" />
        </p>
      </div>
    </div>
  );
}
