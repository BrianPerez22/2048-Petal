import type { Config } from 'tailwindcss';

export default {
  content: ['./index.html', './src/**/*.{ts,tsx}'],
  theme: {
    extend: {
      keyframes: {
        float: {
          '0%': { transform: 'translateY(0px) rotate(0deg)' },
          '50%': { transform: 'translateY(-30px) rotate(180deg)' },
          '100%': { transform: 'translateY(0px) rotate(360deg)' },
        },
        popIn: {
          '0%': { opacity: '0', transform: 'scale(0.4)' },
          '100%': { opacity: '1', transform: 'scale(1)' },
        },
        slideIn: {
          '0%': { opacity: '0', transform: 'translateX(28px)' },
          '100%': { opacity: '1', transform: 'translateX(0)' },
        },
        pulseFast: {
          '0%, 100%': { transform: 'scale(1)' },
          '50%': { transform: 'scale(1.08)' },
        },
      },
      animation: {
        float: 'float 20s ease-in-out infinite',
        'pop-in': 'popIn 0.18s cubic-bezier(0.175, 0.885, 0.32, 1.275) forwards',
        'pulse-fast': 'pulseFast 0.25s ease-in-out forwards',
        'slide-in': 'slideIn 0.3s ease-out forwards',
        'spin-slow': 'spin 12s linear infinite',
      },
    },
  },
  plugins: [],
} satisfies Config;
