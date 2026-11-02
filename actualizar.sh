#!/usr/bin/env bash
# actualizar.sh - Diagnostica y corrige el 404 de GitHub Pages
# Repo: git@github.com:BrianPerez22/2048-Petal.git
# Uso: colocar en la carpeta del proyecto y ejecutar:  bash actualizar.sh

set -e

REPO_SSH="git@github.com:BrianPerez22/2048-Petal.git"
URL_SITIO="https://brianperez22.github.io/2048-Petal/"

echo "==> Verificando que estás dentro de un repositorio git..."
if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  echo "No hay repo aquí. Inicializando y conectando con $REPO_SSH"
  git init
  git remote add origin "$REPO_SSH"
fi

# Ir a la raíz del repo
cd "$(git rev-parse --show-toplevel)"

# Asegurar el remote correcto
if git remote get-url origin >/dev/null 2>&1; then
  ACTUAL="$(git remote get-url origin)"
  if [ "$ACTUAL" != "$REPO_SSH" ]; then
    echo "==> Ajustando remote origin a $REPO_SSH (antes: $ACTUAL)"
    git remote set-url origin "$REPO_SSH"
  fi
else
  git remote add origin "$REPO_SSH"
fi

RAMA="$(git branch --show-current)"
[ -z "$RAMA" ] && RAMA="main" && git checkout -B main
echo "==> Rama actual: $RAMA"

echo "==> Buscando index.html (sin importar mayúsculas)..."
ENCONTRADO="$(find . -path ./.git -prune -o -iname 'index.html' -print | head -n 1)"

if [ -z "$ENCONTRADO" ]; then
  echo "ERROR: No existe ningún index.html en el proyecto."
  echo "Si tu juego se genera con build (npm run build), copia el contenido de la carpeta"
  echo "generada (dist/ o build/) a la raíz, o publica con GitHub Actions."
  exit 1
fi

echo "    Encontrado: $ENCONTRADO"

# Caso 1: está en una subcarpeta -> moverlo a la raíz junto con sus archivos
DIR_INDEX="$(dirname "$ENCONTRADO")"
if [ "$DIR_INDEX" != "." ]; then
  echo "==> index.html está en '$DIR_INDEX', no en la raíz."
  read -r -p "¿Mover el contenido de '$DIR_INDEX' a la raíz? (s/N) " R
  if [[ "$R" =~ ^[sS]$ ]]; then
    shopt -s dotglob
    for f in "$DIR_INDEX"/*; do
      git mv "$f" . 2>/dev/null || mv "$f" .
    done
    shopt -u dotglob
    rmdir "$DIR_INDEX" 2>/dev/null || true
    ENCONTRADO="./$(basename "$ENCONTRADO")"
  else
    echo "Entonces en GitHub: Settings > Pages > Folder y elige la carpeta correcta (solo '/' o '/docs')."
  fi
fi

# Caso 2: nombre con mayúsculas -> forzar minúsculas (en 2 pasos para Windows/macOS)
NOMBRE="$(basename "$ENCONTRADO")"
if [ "$NOMBRE" != "index.html" ] && [ "$DIR_INDEX" = "." ]; then
  echo "==> Renombrando '$NOMBRE' a 'index.html'"
  git mv -f "$NOMBRE" "tmp_index_rename" 2>/dev/null || mv "$NOMBRE" "tmp_index_rename"
  git mv -f "tmp_index_rename" "index.html" 2>/dev/null || mv "tmp_index_rename" "index.html"
fi

# Evita que Jekyll ignore archivos/carpetas (por ejemplo los que empiezan con _)
if [ ! -f .nojekyll ]; then
  echo "==> Creando .nojekyll"
  touch .nojekyll
fi

echo "==> Guardando cambios..."
git add -A
if git diff --cached --quiet; then
  echo "    No hay cambios nuevos que guardar."
else
  git commit -m "Corregir estructura para GitHub Pages (index.html en la raíz)"
fi

echo "==> Subiendo a GitHub (origin/$RAMA)..."
git push -u origin "$RAMA"

echo
echo "Listo. Ahora revisa en GitHub:"
echo "  Repo > Settings > Pages > Source: 'Deploy from a branch'"
echo "  Branch: $RAMA   Folder: / (root)"
echo
echo "Tu sitio (espera 1-2 min y recarga con Ctrl+F5):"
echo "  $URL_SITIO"
