#!/usr/bin/env bash
# =============================================================================
#  actualizar.sh — ACTUALIZACIÓN 2048 Petal v2.0 (autocontenido)
#  Aplica los cambios, compila y sube la actualización a GitHub
#
#  Uso:
#    ./actualizar.sh                     # mensaje de commit automático
#    ./actualizar.sh "mi mensaje"        # mensaje propio
#    ./actualizar.sh -f "mi mensaje"     # fuerza el push (reemplaza main remoto)
#    ./actualizar.sh --sin-push          # solo aplica, compila y hace commit local
#    ./actualizar.sh --reaplicar         # vuelve a escribir los archivos de la actualización
#    ./actualizar.sh --ayuda
#
#  Variables opcionales:
#    REPO_URL   remoto a usar (por defecto: git@github.com:BrianPerez22/2048-Petal.git)
#    RAMA       rama a subir  (por defecto: main)
# =============================================================================
set -euo pipefail

REPO_URL="${REPO_URL:-git@github.com:BrianPerez22/2048-Petal.git}"
RAMA="${RAMA:-main}"
PAGES_URL="https://brianperez22.github.io/2048-Petal/"

FORZAR=0
PUSH=1
REAPLICAR=0
MENSAJE=""
PAYLOAD_ID="7e6c6507c0480faa"

# ---------- colores (solo si hay terminal) ----------
if [ -t 1 ]; then
  C_OK=$'\033[1;32m'; C_INFO=$'\033[1;36m'; C_WARN=$'\033[1;33m'; C_ERR=$'\033[1;31m'; C_OFF=$'\033[0m'
else
  C_OK=""; C_INFO=""; C_WARN=""; C_ERR=""; C_OFF=""
fi
paso()  { echo "${C_INFO}🌼 $*${C_OFF}"; }
ok()    { echo "${C_OK}✔ $*${C_OFF}"; }
aviso() { echo "${C_WARN}⚠ $*${C_OFF}"; }
fallo() { echo "${C_ERR}✖ $*${C_OFF}" >&2; exit 1; }

ayuda() { sed -n '2,18p' "$0" | sed 's/^# \{0,1\}//'; exit 0; }

# ---------- argumentos ----------
while [ $# -gt 0 ]; do
  case "$1" in
    -f|--forzar)   FORZAR=1 ;;
    --sin-push)    PUSH=0 ;;
    --reaplicar)   REAPLICAR=1 ;;
    -h|--ayuda|--help) ayuda ;;
    -*)            fallo "Opción desconocida: $1 (usa --ayuda)" ;;
    *)             MENSAJE="$1" ;;
  esac
  shift
done

# ---------- ir a la carpeta del proyecto ----------
cd "$(dirname "${BASH_SOURCE[0]}")"

command -v tar    >/dev/null 2>&1 || fallo "Falta tar."
command -v base64 >/dev/null 2>&1 || fallo "Falta base64."
command -v git  >/dev/null 2>&1 || fallo "Falta git."
command -v node >/dev/null 2>&1 || fallo "Falta Node.js (18 o superior)."
command -v npm  >/dev/null 2>&1 || fallo "Falta npm."

# ---------- 0) aplicar la actualización ----------
paso "0/4  Aplicando archivos de la v2.0"
if [ "$REAPLICAR" -eq 0 ] && [ -f .petal-update ] && [ "$(cat .petal-update)" = "$PAYLOAD_ID" ]; then
  ok "La actualización ya estaba aplicada (usa --reaplicar para reescribirla)"
else
  awk '/^__PAYLOAD__$/{f=1;next} f' "$0" | base64 -d | tar xzf - \
    || fallo "No pude extraer la actualización (¿el script se editó o se cortó?)."
  # archivos que ya no existen en la v2.0
  rm -rf dist src/components/TutorialModal.tsx
  echo "$PAYLOAD_ID" > .petal-update
  ok "Archivos escritos (src, estilos, workflow de Pages, README, assets...)"
fi

NODE_MAJOR="$(node -p 'process.versions.node.split(".")[0]')"
[ "$NODE_MAJOR" -ge 18 ] || fallo "Se necesita Node 18 o superior (tienes $(node -v))."

VERSION="$(node -p "require('./package.json').version")"

# ---------- 1) dependencias ----------
paso "1/4  Dependencias"
if [ ! -d node_modules ] || [ package.json -nt node_modules ] || [ -f package-lock.json -a package-lock.json -nt node_modules ]; then
  if [ -f package-lock.json ]; then npm ci --no-audit --no-fund || npm install --no-audit --no-fund
  else npm install --no-audit --no-fund; fi
  touch node_modules
else
  ok "node_modules al día"
fi

# ---------- 2) compilar ----------
paso "2/4  Compilando (tipos + build)"
npm run build
[ -f docs/index.html ] || fallo "La compilación no generó docs/index.html."
ok "docs/index.html listo ($(du -h docs/index.html | cut -f1))"

# ---------- 3) git ----------
paso "3/4  Preparando git"
if [ ! -d .git ]; then
  git init -q
  aviso "Repositorio nuevo inicializado."
fi
git checkout -q -B "$RAMA" 2>/dev/null || git branch -M "$RAMA"

if git remote get-url origin >/dev/null 2>&1; then
  ACTUAL="$(git remote get-url origin)"
  if [ "$ACTUAL" != "$REPO_URL" ]; then
    aviso "origin apuntaba a $ACTUAL → lo cambio a $REPO_URL"
    git remote set-url origin "$REPO_URL"
  fi
else
  git remote add origin "$REPO_URL"
fi

# Si es un git recién creado y el remoto ya tiene historia, nos colgamos de ella
# para que la actualización masiva quede como un commit encima (sin borrar el pasado).
if ! git rev-parse --verify -q HEAD >/dev/null 2>&1 && [ "$PUSH" -eq 1 ]; then
  if git fetch -q origin "$RAMA" 2>/dev/null; then
    git reset -q --soft "origin/$RAMA"
    ok "Enlazado con el historial existente de origin/$RAMA"
  fi
fi

git add -A

if git diff --cached --quiet; then
  ok "No hay cambios nuevos que subir."
else
  [ -n "$MENSAJE" ] || MENSAJE="feat: 2048 Petal v${VERSION} — actualización masiva (React + TypeScript + Tailwind)"
  git commit -q -m "$MENSAJE"
  ok "Commit creado: $MENSAJE"
fi

# ---------- 4) push ----------
if [ "$PUSH" -eq 0 ]; then
  aviso "Modo --sin-push: no se sube nada."
  exit 0
fi

paso "4/4  Subiendo a $REPO_URL ($RAMA)"
if [ "$FORZAR" -eq 1 ]; then
  aviso "Push forzado: reemplazará lo que haya en origin/$RAMA."
  git push -u --force-with-lease origin "$RAMA" || git push -u --force origin "$RAMA"
else
  if ! git push -u origin "$RAMA"; then
    echo
    fallo "El push fue rechazado (el remoto tiene cambios que no tienes). Haz 'git pull --rebase origin $RAMA' o vuelve a correr el script con -f si quieres reemplazar el remoto."
  fi
fi
ok "Código subido."

# ---------- GitHub Pages ----------
if command -v gh >/dev/null 2>&1 && gh auth status >/dev/null 2>&1; then
  SLUG="$(echo "$REPO_URL" | sed -E 's#^.*github\.com[:/]##; s#\.git$##')"
  if gh api "repos/${SLUG}/pages" >/dev/null 2>&1; then
    gh api -X PUT "repos/${SLUG}/pages" -f build_type=workflow >/dev/null 2>&1 || true
  else
    gh api -X POST "repos/${SLUG}/pages" -f build_type=workflow >/dev/null 2>&1 || true
  fi
  ok "Pages configurado para usar GitHub Actions."
else
  aviso "Si la página no carga: Settings → Pages → Source → GitHub Actions (una sola vez)."
fi

echo
ok "Listo 🌻  En 1–2 minutos estará en: ${PAGES_URL}"
echo "   Estado del despliegue: https://github.com/BrianPerez22/2048-Petal/actions"

exit 0
__PAYLOAD__
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
nf7JwVr56EvD6hwtPxkxjJp6D1kTJiojxhDeIwnMXVW1xmhshT0w1p36BtJk6s2eoz3tSsHX4xMk
/3VqWlwv2BtnWuvgLF0w93PVs1OjuZpM7R6tXJ8cForpanJrM5/NqMmt9vFZ66R1Wknm01XzNLO3
Udo+Pd4ebH/J7Zy0M0ZXa5ZKp1dO/rKY3/pWLdeT8AvoSRBp455wPXqXkv6ZwyLU5I+L8JntXdKT
R8Y2zmv7hd3K6r7ZnG/395RSoXJZOSt8WS205avr/nsrt7xVzpy33/ca26e5hqFe5q8yVwelvfcn
xWJ761qpFvurXw531sySpfV3Km1dlX8dqqbx/OHJpk1Yff4whaVOPY2+qO2b9avDy1yunWw2i5Vd
ZWu+ftYeKNv6xubNl7NVI1+Ur9+vFg73uqXj3uX+e3vDbMm9asqS+7dWtns6b39ollJ7qqoMLut7
yodMc+1XOliegP8MA0XrChskmjL1AO2VziuWtTo/OM211PKqs/LF2DdvOofFeWdvW1vv3Wzrq93e
1k3T/tJV5MZaXb1RbrX15Uryi7mxo62uWurJ3m6ve7PeqZp7+qBvL2davyY+N3bBSX/DeZgA3BsB
trKkpzgNq+yWbzLL6+eZ0+aynm87heXBe/OgI++051fWzyq7jXr2fX6jWehVy6v752u9nS/Z7Je9
6515TdE6xRN9cNY+XDazH7KZ+WtVaWwXz1eyZ08n806nvRRl3uJTy7xTrFrfrFvz1ilhZZpCq3a6
Vdha6SbfZ+dvk5udQcPZLFxW83sndTM3P5/PyJWbFbVT/TB/Ztfm19N6+fp9buXEzFTP5i/X1/fr
5x82s+f1eu28elzd2tlbOc2rle7W0w3skMJsaMxqmiEW9TVxkERVomz9Tlza3zDmDxImmRznbSzo
oX/80r6J26refBLGO6FOJJLxOaZmxEc7qfZuvXRzOyjmT1YzaeNYu75t5EzncLk+qBzUbbVVvjH1
/dRBv/6ht5Hup64qZTV5vHlrnK1p7e5V/zh33UpeXmX7qaOjylqzk8s0n/pYNSDY/wr2JvFHIihy
MPLsJEVqnUBU9MhmWrJK5TcH26nSRuZay9bXa+3VleturnW8bqY2tx3jTCk6gyNN7bY166C8nW/W
zNrJuvZhd3czd7vzPqtsV84OMtfnmWXrOJs154vbu1Z1Pfn+hazGkBW3Yj4+9bjAgUjcn1PTQrf3
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
eA2v4c8Y/gP6v/9/AEgDAA==
