# 🌼 2048 Petal v2.0

El clásico 2048 con margaritas y girasoles. Hecho con **React + TypeScript + Tailwind CSS** (100 % front-end, sin backend).

## Jugar sin instalar nada

Abre **`dist/index.html`** con doble clic. Es un único archivo con todo incluido (JS, CSS e íconos), funciona offline y desde `file://`.

## Desarrollo

Requiere Node.js 18 o superior.

```bash
npm install
npm run dev        # servidor local con recarga en caliente
npm run build      # revisa tipos y regenera dist/index.html
npm run typecheck  # solo revisa tipos
```

> Después de cambiar código, ejecuta `npm run build` para actualizar `dist/index.html`.

## Controles

- Flechas del teclado o **WASD**
- Deslizar el dedo en móvil
- **Deshacer**: configura el máximo (0–10) con el slider antes del primer movimiento

## Estructura

```
src/
├── App.tsx                 # Composición de la pantalla
├── main.tsx                # Punto de entrada
├── types.ts                # Tile, Board, Direction, GameRecord
├── game/
│   ├── logic.ts            # Lógica pura: mover, fusionar, game over
│   └── reducer.ts          # Estado del juego (useReducer)
├── hooks/
│   ├── useGame.ts          # Estado + persistencia + sonido
│   ├── useKeyboard.ts
│   └── useSwipe.ts
├── lib/
│   ├── audio.ts            # Sonido de burbuja (Web Audio)
│   ├── favicon.ts
│   └── storage.ts          # localStorage seguro
└── components/             # Header, Board, TileView, paneles, modales, íconos
```

El récord y el historial se guardan en `localStorage` con las mismas claves de la v1, así que no se pierden al actualizar.
