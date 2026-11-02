# Changelog

## 2.0.0

### Arquitectura
- El archivo único `App.tsx` se separó en módulos: lógica pura (`game/`), hooks, utilidades (`lib/`) y componentes.
- Estado del juego movido a un `useReducer`; el sonido y el guardado se disparan como efectos.
- Proyecto con Vite + Tailwind CSS compilado (ya no depende de un CDN ni de un `<style>` embebido).
- Build en un solo archivo (`dist/index.html`) que se abre localmente sin servidor.

### Correcciones
- Mover el slider de "Max Deshacer" ya no reinicia la partida.
- Las flores del fondo no cambian de posición en cada movimiento.
- El audio reutiliza un único `AudioContext` (antes creaba uno por sonido).
- Atajos como Ctrl+S / Cmd+A ya no se bloquean por las teclas WASD (solo actúan sin modificadores).
- El teclado no mueve fichas mientras el tutorial está abierto.
- Deslizar sobre el tablero en móvil ya no desplaza la página (`touch-none`).
- Deshacer ya no repite la animación de aparición/fusión en las fichas restauradas.

### Sin cambios
- Diseño, colores, animaciones, reglas, tutorial y claves de `localStorage`.
