import type { ReactNode } from 'react';

export default function KeyCap({ children }: { children: ReactNode }) {
  return (
    <span className="min-w-[2.75rem] h-11 px-3 inline-flex items-center justify-center rounded-lg border-2 border-dashed border-amber-400/70 bg-slate-800 text-amber-300 font-black text-base shadow-[0_3px_0_rgba(251,191,36,0.25)]">
      {children}
    </span>
  );
}
