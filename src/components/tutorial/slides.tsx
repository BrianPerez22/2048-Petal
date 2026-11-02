import type { ReactNode } from 'react';
import { ArrowDown, ArrowLeft, ArrowRight, ArrowUp, Hand, RotateCcw, Smartphone, Volume2 } from 'lucide-react';
import { DaisyPetalSVG } from '../FlowerIcons';
import KeyCap from './KeyCap';
import MiniBoard from './MiniBoard';
import UndoDemo from './UndoDemo';
import { SCENES } from './boards';

export interface Slide {
  id: string;
  render: () => ReactNode;
}

const Title = ({ children }: { children: ReactNode }) => (
  <h2 className="text-3xl sm:text-4xl font-extrabold bg-gradient-to-r from-amber-300 via-yellow-400 to-amber-200 bg-clip-text text-transparent text-center">
    {children}
  </h2>
);

const Text = ({ children, className = '' }: { children: ReactNode; className?: string }) => (
  <p className={`text-slate-200 text-base sm:text-lg leading-relaxed text-center max-w-md mx-auto ${className}`}>
    {children}
  </p>
);

const ControlRow = ({ keys, text }: { keys: ReactNode; text: string }) => (
  <div className="flex flex-col items-center gap-3 bg-slate-950/50 border border-dashed border-slate-700/70 rounded-2xl p-4">
    <div className="flex flex-wrap items-center justify-center gap-2">{keys}</div>
    <p className="text-slate-200 text-sm sm:text-base text-center">{text}</p>
  </div>
);

const intro: Slide = {
  id: 'intro',
  render: () => (
    <div className="flex flex-col items-center gap-4">
      <DaisyPetalSVG className="w-20 h-20 text-amber-50 animate-spin-slow" />
      <Title>¡Bienvenido a 2048 Petal!</Title>
      <Text>
        El juego consiste en mover las fichas en un tablero de 4×4, combinando números iguales hasta hacer
        florecer la ficha 2048. Cada movimiento añade una nueva ficha de 2 o 4.
      </Text>
      <ul className="text-base text-slate-200 flex flex-col gap-3 max-w-lg">
        {[
          'Usa las flechas, WASD o desliza para mover las fichas.',
          'Combina números iguales para que se sumen.',
          'Gana cuando logres obtener la ficha de 2048.',
        ].map((item) => (
          <li key={item} className="flex gap-2 items-start">
            <DaisyPetalSVG className="w-5 h-5 mt-1 shrink-0 text-amber-50" />
            <span>{item}</span>
          </li>
        ))}
      </ul>
    </div>
  ),
};

const sceneSlides: Slide[] = SCENES.map((scene, i) => ({
  id: `scene-${i + 1}`,
  render: () => (
    <div className="w-full flex flex-col lg:flex-row items-center gap-5 lg:gap-10">
      <Text className="lg:flex-1 lg:text-left lg:text-xl lg:mx-0 lg:max-w-none">{scene.text}</Text>
      <div className="w-full lg:flex-1 flex justify-center">
        <MiniBoard cells={scene.cells} highlight={scene.highlight} hint={scene.hint} />
      </div>
    </div>
  ),
}));

const undo: Slide = {
  id: 'undo',
  render: () => (
    <div className="flex flex-col items-center gap-4">
      <RotateCcw className="w-10 h-10 text-amber-400" />
      <Title>El Slider de Deshacer</Title>
      <Text>
        Elige cuántos movimientos atrás puedes revertir, entre 0 y 10. Ajústalo ANTES de tu primer movimiento:
        después se bloquea. ¡Úsalo con estrategia!
      </Text>
      <UndoDemo />
    </div>
  ),
};

const pcControls: Slide = {
  id: 'pc',
  render: () => (
    <div className="flex flex-col items-center gap-4">
      <Title>⌨️ Controles de PC</Title>
      <div className="grid gap-4 w-full max-w-lg">
        <ControlRow
          keys={
            <>
              <KeyCap><ArrowUp className="w-5 h-5" /></KeyCap>
              <KeyCap><ArrowDown className="w-5 h-5" /></KeyCap>
              <KeyCap><ArrowLeft className="w-5 h-5" /></KeyCap>
              <KeyCap><ArrowRight className="w-5 h-5" /></KeyCap>
            </>
          }
          text="Mover fichas con las flechas del teclado"
        />
        <ControlRow
          keys={
            <>
              <KeyCap>W</KeyCap>
              <KeyCap>A</KeyCap>
              <KeyCap>S</KeyCap>
              <KeyCap>D</KeyCap>
            </>
          }
          text="También puedes moverte con WASD"
        />
        <ControlRow
          keys={
            <>
              <KeyCap>U</KeyCap>
              <KeyCap>Ctrl + Z</KeyCap>
            </>
          }
          text="Deshacer el último movimiento"
        />
      </div>
    </div>
  ),
};

const extraControls: Slide = {
  id: 'extra',
  render: () => (
    <div className="flex flex-col items-center gap-4">
      <Title>Sonido y móvil</Title>
      <div className="grid gap-4 w-full max-w-lg">
        <ControlRow
          keys={
            <>
              <KeyCap>M</KeyCap>
              <KeyCap><Volume2 className="w-5 h-5" /></KeyCap>
            </>
          }
          text="Activar o silenciar los sonidos de burbuja"
        />
        <ControlRow
          keys={
            <>
              <Smartphone className="w-10 h-10 text-amber-300" />
              <Hand className="w-10 h-10 text-amber-300 animate-bounce" />
            </>
          }
          text="En el celular, desliza el dedo sobre el tablero en la dirección que quieras"
        />
        <ControlRow
          keys={
            <KeyCap>
              <span className="inline-flex items-center gap-1.5">
                <RotateCcw className="w-5 h-5" /> Reiniciar
              </span>
            </KeyCap>
          }
          text="Empieza una partida nueva con el botón del panel de controles"
        />
      </div>
    </div>
  ),
};

export const SLIDES: Slide[] = [intro, ...sceneSlides, undo, pcControls, extraControls];
