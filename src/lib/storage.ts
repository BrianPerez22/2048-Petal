import type { GameRecord } from '../types';

// Mismas claves que la v1 para conservar el récord y el historial existentes.
const BEST_KEY = '2048_petal_best';
const RECORDS_KEY = '2048_petal_records';

export const loadBestScore = (): number => {
  try {
    const raw = localStorage.getItem(BEST_KEY);
    const n = raw ? parseInt(raw, 10) : 0;
    return Number.isFinite(n) ? n : 0;
  } catch {
    return 0;
  }
};

export const saveBestScore = (score: number): void => {
  try {
    localStorage.setItem(BEST_KEY, String(score));
  } catch {
    // almacenamiento no disponible: se ignora
  }
};

export const loadRecords = (): GameRecord[] => {
  try {
    const raw = localStorage.getItem(RECORDS_KEY);
    if (!raw) return [];
    const parsed: unknown = JSON.parse(raw);
    return Array.isArray(parsed) ? (parsed as GameRecord[]) : [];
  } catch {
    return [];
  }
};

export const saveRecords = (records: GameRecord[]): void => {
  try {
    localStorage.setItem(RECORDS_KEY, JSON.stringify(records));
  } catch {
    // almacenamiento no disponible: se ignora
  }
};
