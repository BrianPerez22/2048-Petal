import { useState } from 'react';
import { useGame } from './hooks/useGame';
import { useKeyboard } from './hooks/useKeyboard';
import FloatingFlowers from './components/FloatingFlowers';
import Header from './components/Header';
import ControlsPanel from './components/ControlsPanel';
import Board from './components/Board';
import HistoryPanel from './components/HistoryPanel';
import TutorialModal from './components/TutorialModal';
import { DaisyPetalSVG } from './components/FlowerIcons';

export default function App() {
  const { state, move, undo, newGame, setMaxUndos, toggleSound, dismissWin } = useGame();
  const [showTutorial, setShowTutorial] = useState(false);

  // Mientras el tutorial está abierto, el teclado no mueve fichas.
  useKeyboard(move, !showTutorial);

  const canUndo = state.undoStack.length > 0 && state.undosRemaining > 0 && !state.gameOver;

  return (
    <div className="min-h-screen bg-[#12141d] text-slate-100 flex flex-col justify-between font-sans relative overflow-x-hidden select-none">
      <FloatingFlowers />

      <Header
        score={state.score}
        bestScore={state.bestScore}
        soundEnabled={state.soundEnabled}
        onToggleSound={toggleSound}
        onOpenTutorial={() => setShowTutorial(true)}
      />

      <main className="relative z-10 w-full max-w-6xl mx-auto px-4 py-4 flex-1 grid grid-cols-1 lg:grid-cols-12 items-center justify-center gap-6">
        <ControlsPanel
          canUndo={canUndo}
          undosRemaining={state.undosRemaining}
          maxUndos={state.maxUndos}
          undoLimitLocked={state.undoLimitLocked}
          onUndo={undo}
          onRestart={newGame}
          onOpenTutorial={() => setShowTutorial(true)}
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

      {showTutorial && <TutorialModal onClose={() => setShowTutorial(false)} />}

      <footer className="relative z-10 w-full text-center py-3 text-xs text-slate-500 border-t border-dashed border-slate-800">
        <p className="flex items-center justify-center gap-1.5">
          <span>Usa las flechas del teclado, WASD o desliza para mover las fichas.</span>
          <DaisyPetalSVG className="w-3.5 h-3.5 text-amber-400 inline" />
        </p>
      </footer>
    </div>
  );
}
