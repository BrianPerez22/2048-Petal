import { StrictMode } from 'react';
import { createRoot } from 'react-dom/client';
import App from './App';
import { injectDaisyFavicon } from './lib/favicon';
import './index.css';

injectDaisyFavicon();

createRoot(document.getElementById('root')!).render(
  <StrictMode>
    <App />
  </StrictMode>
);
