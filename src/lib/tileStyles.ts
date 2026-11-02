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
