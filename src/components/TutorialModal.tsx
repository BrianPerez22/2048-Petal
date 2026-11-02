import { useState } from 'react';
import type { ReactNode } from 'react';
import { ArrowDown, ArrowLeft, ArrowRight, ArrowUp, ChevronRight, RotateCcw, X } from 'lucide-react';
import { DaisyPetalSVG } from './FlowerIcons';

interface Step {
  title: string;
  description: string;
  icon: ReactNode;
}

const keyBox = 'p-2 border border-dashed border-amber-400 rounded-lg bg-slate-800';

const STEPS: Step[] = [
  {
    title: '¡Bienvenido a 2048 Petal!',
    description:
      'Tu objetivo es combinar fichas con los mismos valores florales hasta hacer florecer la ficha 2048 (¡o superar tu propio récord!).',
    icon: <DaisyPetalSVG className="w-12 h-12 text-amber-300 animate-spin-slow" />,
  },
  {
    title: '¿Cómo Jugar?',
    description:
      'Usa las Teclas de Dirección (Flechas), WASD en tu teclado o Desliza con el dedo (Swipe) en tu pantalla móvil para mover todas las fichas en una dirección.',
    icon: (
      <div className="flex gap-2 text-amber-300">
        <div className={keyBox}><ArrowLeft className="w-5 h-5" /></div>
        <div className="flex flex-col gap-1">
          <div className={keyBox}><ArrowUp className="w-5 h-5" /></div>
          <div className={keyBox}><ArrowDown className="w-5 h-5" /></div>
        </div>
        <div className={keyBox}><ArrowRight className="w-5 h-5" /></div>
      </div>
    ),
  },
  {
    title: 'Fusión y Brillo Floral',
    description:
      'Cuando dos fichas iguales chocan, ¡se fusionan en una nueva ficha con el doble de valor y emiten un hermoso destello floral!',
    icon: (
      <div className="flex items-center gap-3">
        <div className="w-10 h-10 bg-amber-100 text-amber-900 font-bold rounded-xl flex items-center justify-center border border-dashed border-amber-300">2</div>
        <span className="text-amber-400 font-bold text-xl">+</span>
        <div className="w-10 h-10 bg-amber-100 text-amber-900 font-bold rounded-xl flex items-center justify-center border border-dashed border-amber-300">2</div>
        <span className="text-amber-400 font-bold text-xl">=</span>
        <div className="w-12 h-12 bg-amber-200 text-amber-950 font-black rounded-xl flex items-center justify-center border-2 border-dashed border-amber-400 ring-4 ring-amber-300/80 shadow-[0_0_20px_rgba(251,191,36,0.9)]">4</div>
      </div>
    ),
  },
  {
    title: 'Deshacer Movimientos (Undo)',
    description:
      'Puedes configurar la cantidad máxima de Deshacer (hasta 10) con el slider ANTES de realizar tu primer movimiento de la partida.',
    icon: <RotateCcw className="w-10 h-10 text-amber-400" />,
  },
];

export default function TutorialModal({ onClose }: { onClose: () => void }) {
  const [step, setStep] = useState(0);
  const current = STEPS[step];
  const isLast = step === STEPS.length - 1;

  return (
    <div className="fixed inset-0 z-50 bg-slate-950/80 backdrop-blur-md flex items-center justify-center p-4">
      <div className="bg-slate-900 border-2 border-dashed border-amber-400/60 rounded-3xl p-6 max-w-md w-full shadow-2xl relative flex flex-col items-center text-center animate-pop-in">
        <button
          onClick={onClose}
          className="absolute top-4 right-4 p-1.5 text-slate-400 hover:text-amber-300 rounded-xl hover:bg-slate-800 transition-all"
          aria-label="Cerrar tutorial"
        >
          <X className="w-5 h-5" />
        </button>

        <div className="h-20 flex items-center justify-center my-3">{current.icon}</div>

        <h3 className="text-xl font-extrabold text-amber-300 mb-2">{current.title}</h3>

        <p className="text-slate-300 text-sm leading-relaxed mb-6 min-h-[60px] flex items-center justify-center">
          {current.description}
        </p>

        <div className="flex items-center justify-between w-full pt-4 border-t border-dashed border-slate-800">
          <div className="flex gap-1">
            {STEPS.map((_, idx) => (
              <div
                key={idx}
                className={`h-2 rounded-full transition-all ${idx === step ? 'w-6 bg-amber-400' : 'w-2 bg-slate-700'}`}
              />
            ))}
          </div>

          <div className="flex gap-2">
            {step > 0 && (
              <button
                onClick={() => setStep((s) => s - 1)}
                className="px-3 py-1.5 bg-slate-800 hover:bg-slate-700 text-slate-300 font-bold rounded-xl text-xs transition-all border border-dashed border-slate-600"
              >
                Anterior
              </button>
            )}
            {isLast ? (
              <button
                onClick={onClose}
                className="px-4 py-1.5 bg-amber-400 hover:bg-amber-300 text-slate-950 font-black rounded-xl text-xs shadow-md transition-all"
              >
                ¡Entendido!
              </button>
            ) : (
              <button
                onClick={() => setStep((s) => s + 1)}
                className="px-4 py-1.5 bg-gradient-to-r from-amber-500 to-orange-500 hover:from-amber-400 hover:to-orange-400 text-white font-bold rounded-xl text-xs shadow-md transition-all flex items-center gap-1 border border-dashed border-amber-300/40"
              >
                Siguiente
                <ChevronRight className="w-3.5 h-3.5" />
              </button>
            )}
          </div>
        </div>
      </div>
    </div>
  );
}
