import { defineConfig } from 'vite';
import react from '@vitejs/plugin-react';
import { viteSingleFile } from 'vite-plugin-singlefile';

// viteSingleFile() mete todo (JS + CSS) dentro de dist/index.html,
// así que el resultado se puede abrir con doble clic (file://) sin servidor.
export default defineConfig({
  base: './',
  plugins: [react(), viteSingleFile()],
});
