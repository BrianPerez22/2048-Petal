import { useMemo } from 'react';
import { DaisyPetalSVG, SunflowerSVG } from './FlowerIcons';

const FLOWER_COUNT = 24;

/** Fondo de margaritas y girasoles flotando. Las posiciones se calculan una sola vez. */
export default function FloatingFlowers() {
  const flowers = useMemo(
    () =>
      Array.from({ length: FLOWER_COUNT }, (_, i) => ({
        id: i,
        isSunflower: i % 2 === 0,
        left: `${Math.random() * 100}%`,
        top: `${Math.random() * 100}%`,
        size: Math.random() * 28 + 22,
        duration: Math.random() * 18 + 14,
        delay: Math.random() * 6,
        opacity: Math.random() * 0.3 + 0.15,
      })),
    []
  );

  return (
    <div className="fixed inset-0 pointer-events-none overflow-hidden z-0" aria-hidden="true">
      {flowers.map((f) => (
        <div
          key={f.id}
          className="absolute animate-float"
          style={{
            left: f.left,
            top: f.top,
            width: `${f.size}px`,
            height: `${f.size}px`,
            animationDuration: `${f.duration}s`,
            animationDelay: `${f.delay}s`,
            opacity: f.opacity,
          }}
        >
          {f.isSunflower ? (
            <SunflowerSVG className="w-full h-full" />
          ) : (
            <DaisyPetalSVG className="w-full h-full text-amber-50" />
          )}
        </div>
      ))}
    </div>
  );
}
