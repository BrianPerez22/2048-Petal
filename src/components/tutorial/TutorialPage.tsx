import { useCallback, useEffect, useState } from 'react';
import { ChevronLeft, ChevronRight, Gamepad2, Lightbulb } from 'lucide-react';
import Brand from '../Brand';
import { DaisyPetalSVG, SunflowerSVG } from '../FlowerIcons';
import { useSwipe } from '../../hooks/useSwipe';
import { SLIDES } from './slides';

interface TutorialPageProps {
  onPlay: () => void;
}

const TIPS = [
  'Mantén las fichas grandes en una esquina.',
  'Usa principalmente 3 direcciones.',
  'Planifica varios movimientos por adelantado.',
];

export default function TutorialPage({ onPlay }: TutorialPageProps) {
  const [index, setIndex] = useState(0);
  const last = SLIDES.length - 1;

  const prev = useCallback(() => setIndex((i) => Math.max(0, i - 1)), []);
  const next = useCallback(() => setIndex((i) => Math.min(last, i + 1)), [last]);

  // En el tutorial, deslizar izquierda/derecha cambia de slide
  const swipe = useSwipe(
    useCallback(
      (dir) => {
        if (dir === 'LEFT') next();
        if (dir === 'RIGHT') prev();
      },
      [next, prev]
    )
  );

  useEffect(() => {
    const handler = (e: KeyboardEvent) => {
      if (e.ctrlKey || e.metaKey || e.altKey) return;
      if (e.key === 'ArrowRight') next();
      else if (e.key === 'ArrowLeft') prev();
      else if (e.key === 'Escape') onPlay();
    };
    window.addEventListener('keydown', handler);
    return () => window.removeEventListener('keydown', handler);
  }, [next, prev, onPlay]);

  const slide = SLIDES[index];
  const isLast = index === last;

  const navBtn =
    'px-3 sm:px-4 py-2.5 bg-slate-800 hover:bg-slate-700 text-slate-200 font-bold rounded-xl border border-dashed border-slate-600 flex items-center justify-center gap-1.5 transition-all text-sm sm:text-base active:scale-95 shadow-md disabled:opacity-40 disabled:cursor-not-allowed';
  const playBtn =
    'px-4 py-2.5 bg-gradient-to-r from-amber-500 to-orange-500 hover:from-amber-400 hover:to-orange-400 text-white font-bold rounded-xl shadow-lg border border-dashed border-amber-200 flex items-center justify-center gap-2 transition-all text-sm sm:text-base active:scale-95';

  return (
    <>
      <header className="relative z-10 w-full max-w-6xl mx-auto px-4 pt-5 pb-3 flex flex-col sm:flex-row items-center justify-between gap-3 sm:gap-4 border-b border-dashed border-slate-700/60">
        <Brand subtitle="Tutorial" />
        <button onClick={onPlay} className={playBtn}>
          <Gamepad2 className="w-5 h-5" />
          Jugar
        </button>
      </header>

      <main className="relative z-10 w-full max-w-6xl mx-auto px-4 py-4 sm:py-6 flex-1 grid grid-cols-1 lg:grid-cols-12 items-start lg:items-center gap-5 lg:gap-8">
        {/* CENTRO: carrusel (más ancho para que tablero y texto respiren) */}
        <div className="lg:col-span-8 w-full order-1 flex flex-col items-center gap-4">
          <div
            {...swipe}
            className="w-full max-w-3xl min-h-[420px] sm:min-h-[500px] bg-slate-900/80 border-2 border-dashed border-amber-400/50 rounded-3xl p-4 sm:p-6 lg:p-8 shadow-2xl backdrop-blur-md flex items-center justify-center touch-pan-y"
          >
            <div key={slide.id} className="w-full animate-slide-in">
              {slide.render()}
            </div>
          </div>

          <div className="w-full max-w-3xl flex items-center justify-between gap-3">
            <button onClick={prev} disabled={index === 0} className={navBtn} aria-label="Paso anterior">
              <ChevronLeft className="w-5 h-5" />
              <span className="hidden sm:inline">Atrás</span>
            </button>

            <div className="flex items-center gap-1.5 flex-wrap justify-center flex-1 max-w-[260px]">
              {SLIDES.map((s, i) => (
                <button
                  key={s.id}
                  onClick={() => setIndex(i)}
                  aria-label={`Ir al paso ${i + 1}`}
                  className={`h-2.5 rounded-full transition-all ${
                    i === index ? 'w-7 bg-amber-400' : 'w-2.5 bg-slate-700 hover:bg-slate-500'
                  }`}
                />
              ))}
            </div>

            {isLast ? (
              <button onClick={onPlay} className={playBtn}>
                ¡A jugar!
              </button>
            ) : (
              <button onClick={next} className={navBtn} aria-label="Paso siguiente">
                <span className="hidden sm:inline">Sigue</span>
                <ChevronRight className="w-5 h-5" />
              </button>
            )}
          </div>

          <p className="text-xs sm:text-sm text-slate-400 text-center">
            Paso {index + 1} de {SLIDES.length} · usa ← → o desliza
          </p>
        </div>

        {/* DERECHA: mascota + consejos */}
        <div className="lg:col-span-4 w-full order-2 flex flex-col gap-4 max-w-3xl mx-auto lg:max-w-none">
          <div className="bg-slate-900/80 border border-dashed border-slate-700/80 rounded-3xl p-4 sm:p-5 backdrop-blur-md shadow-xl flex flex-row lg:flex-col items-center gap-4 text-left lg:text-center">
            <button onClick={onPlay} aria-label="Ir al juego" className="shrink-0 active:scale-95 transition-transform">
              <SunflowerSVG className="w-16 h-16 sm:w-20 sm:h-20 animate-spin-slow" />
            </button>
            <p className="text-sm sm:text-base text-slate-200 leading-relaxed">
              Aprende a dominar el 2048 con estas estrategias y controles.{' '}
              <span className="text-amber-300 font-bold">¡Pétalo te guía!</span>
            </p>
          </div>

          <div className="bg-slate-900/60 border border-dashed border-amber-500/30 rounded-2xl p-4 sm:p-5 backdrop-blur-md flex flex-col gap-3 text-sm sm:text-base text-slate-200">
            <h3 className="font-bold text-amber-300 flex items-center gap-2 text-base sm:text-lg">
              <Lightbulb className="w-5 h-5" />
              Consejos
            </h3>
            {TIPS.map((tip) => (
              <p key={tip} className="flex gap-2.5 items-start">
                <DaisyPetalSVG className="w-4 h-4 mt-1 shrink-0 text-amber-50" />
                {tip}
              </p>
            ))}
          </div>
        </div>
      </main>
    </>
  );
}
