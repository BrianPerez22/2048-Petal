#!/usr/bin/env bash
# =============================================================================
# actualizar.sh  ·  2048 Petal
#
# Qué hace (en orden):
#   1. Aplica el parche v2.0.1 (guarda copia de lo que reemplaza):
#        - Fichas alineadas con las casillas en Safari iOS y demás navegadores
#        - Tutorial rediseñado: tablero más grande, texto legible, mejor reparto
#   2. npm install  →  npm run build  (regenera docs/index.html)
#   3. git add / commit / push a main  (GitHub Actions publica en Pages)
#
# Uso:
#   ./actualizar.sh                       # parche + build + commit + push
#   ./actualizar.sh "mi mensaje"          # igual, con tu mensaje de commit
#   ./actualizar.sh --sin-parche "msg"    # NO toca el código; solo build + push
#   ./actualizar.sh --sin-push            # parche + build, sin subir a GitHub
#   ./actualizar.sh --ayuda
#
# Si no tiene permiso de ejecución:  chmod +x actualizar.sh   (o:  bash actualizar.sh)
# =============================================================================
set -euo pipefail

REPO_SSH="git@github.com:BrianPerez22/2048-Petal.git"
URL_SITIO="https://brianperez22.github.io/2048-Petal/"
MENSAJE="Corrige alineación de fichas en iOS y rediseña el tutorial"
PARCHE=1
PUSH=1

for arg in "$@"; do
  case "$arg" in
    --ayuda|-h|--help) sed -n '2,23p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
    --sin-parche)      PARCHE=0 ;;
    --sin-push)        PUSH=0 ;;
    --*)               echo "Opción desconocida: $arg  (usa --ayuda)"; exit 1 ;;
    *)                 MENSAJE="$arg" ;;
  esac
done

paso() { printf '\n\033[1;33m==> %s\033[0m\n' "$1"; }
fallo() { printf '\033[1;31mERROR:\033[0m %s\n' "$1" >&2; exit 1; }

# --- Ubicarse en la carpeta del proyecto ------------------------------------
cd "$(dirname "$0")"
[ -f package.json ] && grep -q '"name": "2048-petal"' package.json && [ -d src ] \
  || fallo "Este script debe estar en la raíz del proyecto 2048-Petal (donde está package.json)."

command -v node >/dev/null 2>&1 || fallo "Falta Node.js 18+ (https://nodejs.org)."
command -v npm  >/dev/null 2>&1 || fallo "Falta npm."
command -v git  >/dev/null 2>&1 || fallo "Falta git."

# --- Git: repo y remote ------------------------------------------------------
if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  paso "Inicializando git"
  git init -q
  git checkout -q -B main
fi
if git remote get-url origin >/dev/null 2>&1; then
  [ "$(git remote get-url origin)" = "$REPO_SSH" ] || git remote set-url origin "$REPO_SSH"
else
  git remote add origin "$REPO_SSH"
fi
RAMA="$(git branch --show-current)"
[ -n "$RAMA" ] || RAMA="main"

# --- 1. Parche ---------------------------------------------------------------
RESPALDO=".git/petal-respaldo/$(date +%Y%m%d-%H%M%S)"

# escribir <ruta>  ← lee el contenido nuevo por stdin; respalda el archivo anterior
escribir() {
  local ruta="$1"
  if [ -f "$ruta" ]; then
    mkdir -p "$RESPALDO/$(dirname "$ruta")"
    cp "$ruta" "$RESPALDO/$ruta"
  fi
  mkdir -p "$(dirname "$ruta")"
  cat > "$ruta"
  echo "    ✔ $ruta"
}

aplicar_parche() {
  escribir 'src/components/Board.tsx' <<'PETAL_EOF_1'
import { useMemo } from 'react';
import type { CSSProperties } from 'react';
import type { Board as BoardType, Direction } from '../types';
import { boardToTiles, GRID_SIZE } from '../game/logic';
import { useSwipe } from '../hooks/useSwipe';
import TileView from './TileView';
import GameOverlay from './GameOverlay';

interface BoardProps {
  board: BoardType;
  score: number;
  gameOver: boolean;
  gameWon: boolean;
  onSwipe: (direction: Direction) => void;
  onContinue: () => void;
  onRestart: () => void;
}

/**
 * Las celdas del fondo y las fichas viven en dos capas que ocupan EXACTAMENTE
 * la misma caja (`inset: var(--gap)`), y ambas leen la misma variable --gap.
 * Así el cálculo de cada ficha coincide con su casilla en cualquier navegador.
 */
const LAYER: CSSProperties = { inset: 'var(--gap)' };

export default function Board({
  board,
  score,
  gameOver,
  gameWon,
  onSwipe,
  onContinue,
  onRestart,
}: BoardProps) {
  const tiles = useMemo(() => boardToTiles(board), [board]);
  const swipe = useSwipe(onSwipe);

  return (
    <div className="lg:col-span-6 flex flex-col items-center justify-center w-full order-1 lg:order-2">
      <div
        {...swipe}
        className="relative isolate w-full max-w-md aspect-square bg-[#0c0e15] border-2 border-dashed border-amber-500/40 rounded-3xl shadow-2xl overflow-hidden touch-none [--gap:0.5rem] sm:[--gap:0.75rem]"
      >
        <div className="absolute grid grid-cols-4 grid-rows-4" style={{ ...LAYER, gap: 'var(--gap)' }}>
          {Array.from({ length: GRID_SIZE * GRID_SIZE }).map((_, idx) => (
            <div
              key={idx}
              className="bg-slate-800/40 border border-dashed border-slate-700/60 rounded-xl sm:rounded-2xl"
            />
          ))}
        </div>

        <div className="absolute pointer-events-none" style={LAYER}>
          {tiles.map((tile) => (
            <TileView key={tile.id} tile={tile} />
          ))}
        </div>

        {(gameOver || gameWon) && (
          <GameOverlay
            gameOver={gameOver}
            gameWon={gameWon}
            score={score}
            onContinue={onContinue}
            onRestart={onRestart}
          />
        )}
      </div>
    </div>
  );
}
PETAL_EOF_1

  escribir 'src/components/TileView.tsx' <<'PETAL_EOF_2'
import type { Tile } from '../types';
import { DaisyPetalSVG, SunflowerSVG } from './FlowerIcons';
import { getTileStyle, tileFontSize } from '../lib/tileStyles';

/** Lado de una casilla: (ancho útil − 3 separaciones) / 4. --gap lo define Board.tsx */
const CELL = 'calc((100% - 3 * var(--gap)) / 4)';

/** Desplazamiento de n casillas. En translate(), el 100% es el tamaño de la propia ficha. */
const offset = (n: number) => `calc(${n} * (100% + var(--gap)))`;

export default function TileView({ tile }: { tile: Tile }) {
  return (
    <div
      className="absolute top-0 left-0 transition-transform duration-200 ease-in-out will-change-transform"
      style={{
        width: CELL,
        height: CELL,
        transform: `translate(${offset(tile.col)}, ${offset(tile.row)})`,
      }}
    >
      <div
        className={`w-full h-full rounded-xl sm:rounded-2xl border-2 border-dashed flex flex-col items-center justify-center transform transition-all duration-150 ${getTileStyle(
          tile.value,
          tile.merged
        )} ${tile.isNew ? 'animate-pop-in' : ''}`}
      >
        <span
          className="font-black tracking-tight leading-none drop-shadow-sm"
          style={{ fontSize: tileFontSize(tile.value) }}
        >
          {tile.value}
        </span>
        {tile.value >= 128 &&
          (tile.value >= 512 ? (
            <SunflowerSVG className="w-3 h-3 sm:w-4 sm:h-4 mt-0.5" />
          ) : (
            <DaisyPetalSVG className="w-3 h-3 sm:w-4 sm:h-4 mt-0.5 text-white" />
          ))}
      </div>
    </div>
  );
}
PETAL_EOF_2

  escribir 'src/lib/tileStyles.ts' <<'PETAL_EOF_3'
export const getTileStyle = (value: number, isMerged?: boolean): string => {
  let base: string;
  switch (value) {
    case 2:
      base = 'bg-slate-50 text-slate-800 border-amber-200 shadow-sm';
      break;
    case 4:
      base = 'bg-amber-100 text-amber-900 border-amber-300 shadow-sm';
      break;
    case 8:
      base = 'bg-orange-200 text-orange-950 border-orange-300 shadow-md';
      break;
    case 16:
      base = 'bg-orange-300 text-orange-950 border-orange-400 shadow-md';
      break;
    case 32:
      base = 'bg-orange-400 text-white border-orange-500 shadow-lg';
      break;
    case 64:
      base = 'bg-orange-500 text-white border-orange-600 shadow-lg';
      break;
    case 128:
      base = 'bg-amber-500 text-white border-amber-300 shadow-amber-500/40 shadow-xl';
      break;
    case 256:
      base = 'bg-rose-400 text-white border-rose-300 shadow-rose-400/50 shadow-xl';
      break;
    case 512:
      base = 'bg-rose-500 text-white border-rose-400 shadow-rose-500/60 shadow-xl';
      break;
    case 1024:
      base = 'bg-pink-500 text-white border-pink-300 shadow-pink-500/60 shadow-2xl';
      break;
    case 2048:
      base =
        'bg-gradient-to-r from-amber-400 via-orange-500 to-rose-500 text-white border-amber-200 shadow-orange-500/80 shadow-2xl';
      break;
    default:
      base = 'bg-purple-600 text-white border-purple-300 shadow-2xl';
      break;
  }

  const mergeGlow = isMerged
    ? 'ring-4 ring-amber-300/80 shadow-[0_0_30px_rgba(251,191,36,0.9)] animate-pulse-fast border-amber-200 z-20 scale-105'
    : '';

  return `${base} ${mergeGlow}`;
};

/**
 * Tamaño de letra fluido según los dígitos de la ficha.
 * Usa clamp() con vw para que el número escale con el tablero en cualquier pantalla
 * (iPhone incluido) sin depender de breakpoints.
 */
export const tileFontSize = (value: number): string => {
  if (value < 100) return 'clamp(1.35rem, 8vw, 2.2rem)';
  if (value < 1000) return 'clamp(1.15rem, 6.6vw, 1.9rem)';
  return 'clamp(0.95rem, 5.4vw, 1.6rem)';
};
PETAL_EOF_3

  escribir 'src/App.tsx' <<'PETAL_EOF_4'
import { useEffect } from 'react';
import { useGame } from './hooks/useGame';
import { useKeyboard } from './hooks/useKeyboard';
import { useHashView } from './hooks/useHashView';
import FloatingFlowers from './components/FloatingFlowers';
import Header from './components/Header';
import ControlsPanel from './components/ControlsPanel';
import Board from './components/Board';
import HistoryPanel from './components/HistoryPanel';
import TutorialPage from './components/tutorial/TutorialPage';
import { DaisyPetalSVG } from './components/FlowerIcons';

export default function App() {
  const { state, move, undo, newGame, setMaxUndos, toggleSound, dismissWin } = useGame();
  const [view, goTo] = useHashView();
  const inGame = view === 'game';

  // El teclado solo controla el juego cuando se está viendo el juego.
  useKeyboard({ onMove: move, onUndo: undo, onToggleSound: toggleSound }, inGame);

  useEffect(() => {
    window.scrollTo(0, 0);
  }, [view]);

  const canUndo = state.undoStack.length > 0 && state.undosRemaining > 0 && !state.gameOver;
  const openTutorial = () => goTo('tutorial');

  return (
    <div className="min-h-screen min-h-dvh bg-[#12141d] text-slate-100 flex flex-col justify-between font-sans relative overflow-x-hidden select-none">
      <FloatingFlowers />

      {inGame ? (
        <>
          <Header
            score={state.score}
            bestScore={state.bestScore}
            soundEnabled={state.soundEnabled}
            onToggleSound={toggleSound}
            onOpenTutorial={openTutorial}
          />

          <main className="relative z-10 w-full max-w-6xl mx-auto px-4 py-4 flex-1 grid grid-cols-1 lg:grid-cols-12 items-center justify-center gap-6">
            <ControlsPanel
              canUndo={canUndo}
              undosRemaining={state.undosRemaining}
              maxUndos={state.maxUndos}
              undoLimitLocked={state.undoLimitLocked}
              onUndo={undo}
              onRestart={newGame}
              onOpenTutorial={openTutorial}
              onChangeMaxUndos={setMaxUndos}
            />

            <Board
              board={state.board}
              score={state.score}
              gameOver={state.gameOver}
              gameWon={state.gameWon}
              onSwipe={move}
              onContinue={dismissWin}
              onRestart={newGame}
            />

            <HistoryPanel records={state.records} bestScore={state.bestScore} />
          </main>
        </>
      ) : (
        <TutorialPage onPlay={() => goTo('game')} />
      )}

      <footer className="relative z-10 w-full text-center py-3 text-xs text-slate-500 border-t border-dashed border-slate-800">
        <p className="flex items-center justify-center gap-1.5">
          <span>Usa las flechas del teclado, WASD o desliza para mover las fichas.</span>
          <DaisyPetalSVG className="w-3.5 h-3.5 text-amber-400 inline" />
        </p>
      </footer>
    </div>
  );
}
PETAL_EOF_4

  escribir 'src/components/tutorial/MiniBoard.tsx' <<'PETAL_EOF_5'
import { ArrowDown, ArrowLeft, ArrowRight, ArrowUp } from 'lucide-react';
import { getTileStyle, tileFontSize } from '../../lib/tileStyles';
import type { Direction } from '../../types';

interface MiniBoardProps {
  cells: number[][];
  /** Casillas [fila, columna] que brillan para llamar la atención */
  highlight?: [number, number][];
  /** Movimiento sugerido para esta escena */
  hint?: Direction;
}

const HINT_LABEL: Record<Direction, { text: string; icon: JSX.Element }> = {
  UP: { text: 'Arriba', icon: <ArrowUp className="w-5 h-5" /> },
  DOWN: { text: 'Abajo', icon: <ArrowDown className="w-5 h-5" /> },
  LEFT: { text: 'Izquierda', icon: <ArrowLeft className="w-5 h-5" /> },
  RIGHT: { text: 'Derecha', icon: <ArrowRight className="w-5 h-5" /> },
};

export default function MiniBoard({ cells, highlight = [], hint }: MiniBoardProps) {
  const isHighlighted = (r: number, c: number) => highlight.some(([hr, hc]) => hr === r && hc === c);

  return (
    <div className="w-full flex flex-col items-center gap-4">
      <div
        className="grid grid-cols-4 grid-rows-4 w-full max-w-[420px] aspect-square bg-[#0c0e15] border-2 border-dashed border-amber-500/40 rounded-2xl sm:rounded-3xl shadow-xl [--gap:0.4rem] sm:[--gap:0.6rem]"
        style={{ padding: 'var(--gap)', gap: 'var(--gap)' }}
      >
        {cells.flat().map((value, i) => {
          const r = Math.floor(i / 4);
          const c = i % 4;
          if (value === 0) {
            return (
              <div
                key={i}
                className="rounded-lg sm:rounded-xl bg-slate-800/40 border border-dashed border-slate-700/60"
              />
            );
          }
          return (
            <div
              key={i}
              className={`rounded-lg sm:rounded-xl border-2 border-dashed flex items-center justify-center font-black tracking-tight leading-none ${getTileStyle(
                value
              )} ${isHighlighted(r, c) ? 'ring-2 ring-amber-300 animate-pulse' : ''}`}
              style={{ fontSize: tileFontSize(value) }}
            >
              {value}
            </div>
          );
        })}
      </div>

      {hint && (
        <span className="inline-flex items-center gap-2 px-4 py-1.5 rounded-full border border-dashed border-amber-400/50 bg-amber-500/10 text-amber-300 text-sm sm:text-base font-bold">
          Mueve {HINT_LABEL[hint].text}
          {HINT_LABEL[hint].icon}
        </span>
      )}
    </div>
  );
}
PETAL_EOF_5

  escribir 'src/components/tutorial/TutorialPage.tsx' <<'PETAL_EOF_6'
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
PETAL_EOF_6

  escribir 'src/components/tutorial/slides.tsx' <<'PETAL_EOF_7'
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
PETAL_EOF_7

  escribir 'src/components/tutorial/UndoDemo.tsx' <<'PETAL_EOF_8'
import { useState } from 'react';
import { DaisyPetalSVG } from '../FlowerIcons';

const TOTAL = 10;

/** Slider de práctica: no afecta la partida, solo enseña cómo funciona. */
export default function UndoDemo() {
  const [value, setValue] = useState(6);

  return (
    <div className="w-full max-w-md mx-auto bg-slate-950/60 border border-dashed border-amber-500/30 rounded-2xl p-4 sm:p-5 flex flex-col gap-4">
      <div className="flex items-center justify-between text-base">
        <label htmlFor="undo-demo" className="text-slate-300 font-semibold">
          Max Deshacer:
        </label>
        <span className="text-3xl font-black text-amber-300 tabular-nums">{value}</span>
      </div>

      <input
        id="undo-demo"
        type="range"
        min={0}
        max={TOTAL}
        value={value}
        onChange={(e) => setValue(parseInt(e.target.value, 10))}
        className="w-full accent-amber-400 cursor-pointer h-2"
      />

      <div className="flex justify-between gap-1" aria-hidden="true">
        {Array.from({ length: TOTAL }).map((_, i) => (
          <DaisyPetalSVG
            key={i}
            className={`w-6 h-6 sm:w-7 sm:h-7 text-amber-50 transition-all duration-200 ${
              i < value ? 'opacity-100 scale-100' : 'opacity-20 scale-75 grayscale'
            }`}
          />
        ))}
      </div>

      <p className="text-xs sm:text-sm text-slate-400 italic text-center">
        Cada margarita encendida es un movimiento que podrás deshacer.
      </p>
    </div>
  );
}
PETAL_EOF_8

  escribir 'src/components/tutorial/KeyCap.tsx' <<'PETAL_EOF_9'
import type { ReactNode } from 'react';

export default function KeyCap({ children }: { children: ReactNode }) {
  return (
    <span className="min-w-[2.75rem] h-11 px-3 inline-flex items-center justify-center rounded-lg border-2 border-dashed border-amber-400/70 bg-slate-800 text-amber-300 font-black text-base shadow-[0_3px_0_rgba(251,191,36,0.25)]">
      {children}
    </span>
  );
}
PETAL_EOF_9
}

if [ "$PARCHE" = 1 ]; then
  paso "Aplicando parche (copia de seguridad en $RESPALDO)"
  aplicar_parche
else
  paso "Omitiendo parche (--sin-parche)"
fi

# --- 2. Build ----------------------------------------------------------------
paso "Instalando dependencias"
npm install --no-audit --no-fund

paso "Compilando (revisa tipos + regenera docs/index.html)"
if ! npm run build; then
  echo
  echo "El build falló. Tus archivos originales están en: $RESPALDO"
  echo "Para volver atrás:  cp -R $RESPALDO/src/. src/"
  exit 1
fi

# --- 3. Commit y push --------------------------------------------------------
if [ "$PUSH" = 0 ]; then
  paso "Listo (sin subir a GitHub por --sin-push)"
  echo "Pruébalo abriendo docs/index.html o con:  npm run dev"
  exit 0
fi

paso "Guardando cambios en git"
git add -A
if git diff --cached --quiet; then
  echo "    No hay cambios nuevos que guardar."
else
  git commit -q -m "$MENSAJE"
  echo "    ✔ commit: $MENSAJE"
fi

paso "Subiendo a GitHub ($RAMA)"
if ! git push -u origin "$RAMA"; then
  echo
  echo "El push fue rechazado (probablemente hay cambios nuevos en GitHub)."
  echo "Ejecuta:  git pull --rebase origin $RAMA  y luego vuelve a correr:  ./actualizar.sh --sin-parche"
  exit 1
fi

paso "¡Listo!"
echo "GitHub Actions publicará en 1-2 minutos:  $URL_SITIO"
echo "En el iPhone: cierra la pestaña de Safari y ábrela de nuevo (la caché de iOS es terca)."
