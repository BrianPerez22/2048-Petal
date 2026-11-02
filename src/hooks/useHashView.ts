import { useCallback, useEffect, useState } from 'react';

export type View = 'game' | 'tutorial';

// Solo se usa un #nombre simple: funciona en GitHub Pages y también abriendo el archivo local.
const readView = (): View => (window.location.hash === '#tutorial' ? 'tutorial' : 'game');

export function useHashView(): [View, (view: View) => void] {
  const [view, setView] = useState<View>(readView);

  useEffect(() => {
    const onChange = () => setView(readView());
    window.addEventListener('hashchange', onChange);
    return () => window.removeEventListener('hashchange', onChange);
  }, []);

  const go = useCallback((next: View) => {
    window.location.hash = next === 'tutorial' ? '#tutorial' : '#game';
  }, []);

  return [view, go];
}
