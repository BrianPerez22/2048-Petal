import { defineConfig } from 'vite';
import react from '@vitejs/plugin-react';
import { viteSingleFile } from 'vite-plugin-singlefile';

// viteSingleFile() mete todo (JS + CSS) dentro de docs/index.html:
//  - se abre con doble clic (file://) sin servidor
//  - sirve tal cual en GitHub Pages (base relativa)
export default defineConfig({
  base: './',
  plugins: [react(), viteSingleFile()],
  build: { outDir: 'docs', emptyOutDir: true },
});
