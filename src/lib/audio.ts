let ctx: AudioContext | null = null;

const getContext = (): AudioContext | null => {
  if (ctx) return ctx;
  const AudioCtx =
    window.AudioContext ??
    (window as unknown as { webkitAudioContext?: typeof AudioContext }).webkitAudioContext;
  if (!AudioCtx) return null;
  ctx = new AudioCtx();
  return ctx;
};

/** Sonido de burbuja generado con Web Audio. Reutiliza un único AudioContext. */
export const playBubbleSound = (isMerge = false): void => {
  try {
    const audio = getContext();
    if (!audio) return;
    if (audio.state === 'suspended') void audio.resume();

    const osc = audio.createOscillator();
    const gain = audio.createGain();
    const now = audio.currentTime;

    osc.type = 'sine';
    osc.frequency.setValueAtTime(isMerge ? 620 : 380, now);
    osc.frequency.exponentialRampToValueAtTime(isMerge ? 940 : 520, now + 0.08);

    gain.gain.setValueAtTime(0.3, now);
    gain.gain.exponentialRampToValueAtTime(0.01, now + 0.08);

    osc.connect(gain);
    gain.connect(audio.destination);
    osc.start(now);
    osc.stop(now + 0.09);
  } catch {
    // restricciones de autoplay: se ignoran
  }
};
