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
PAYLOAD_ID="6c8faaeec99885bc"

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
GchUpSZk6uJh7wS0HbXTxWO+CbksBSlrUi4UNEZlubS0Rku9VnUdqK6jdLt0zUJBIpPI8VnrpgGV
OXGbnAPEIa8ncAjMrqHWei3GB9NiEoyZPTDqjAninYsayKgJWWSlppFjkGVRIrLVTp91XD5cknzQ
LB6/VGOvYSmzi+HsdVTua32VRyewmIsZyaJO+n96rsGT9EjWwUm+D+QdHnhgIN7vOAM6mY3Ip4V8
p31pdd+v7af17Zxa3Oyvn63Iq6mz80JVPkyfyyuX+/L58VnvdF7p1Lvbydt86jh/ft65ta+uTaVg
b+U/mO2D5GmruJHbvvmwmdx8MjYSnGSBDUPozBCFbH5qQHfF+cmRGt6CcLlhWtIJIuSXiyKZg/DP
dgYpmAFPLA2MZYOPv0yNrg5ob3Ti1EvatdrJnyorl9k95eTspLHX3jk4OFHqlWr+fGt+e2WlWb06
2l3NnJ3f1A4yViezqhVzztZxTr9Ujvfayv7AcOaXL1M3Vq991rt9v+IUjUL6W0WHKZY0XhSbvOj4
gqdJjWfCC9Us8xpo3NZhEBi/lbMiw8X9Frm2zDaSaXFD/MgMdVoqbOlmTdGflPJYFT61sQ9TU1jG
eH9yvOz0r7Y3SrdKu3naui7lt+rJ3tp+53K5XElfvb8tyhVZ/3La2VhpXd7W9nS7LMtG7/1RU2l3
TtX3ztGXnPE+md0zGvJy+voye/tE289vGwUm2tADpicdDLEmf0zE71MPjXq5cW29f39W75RujCOt
X20b8ubqvr55u2nsZbLLH+yr/pfSe63eLzuV2y/pk9u63ks622vFrS/pcqu4tS6v7+STlc5lyy4f
FfQPareSebLJ/40y2vPMxDDx9qnJwK9siBL8pKmJ4fjg+KQ6+FDbb+flwrZW3lx/X21dn96uqyuw
U1S2SgdblYZltDavd6u3NzuH2ctqdr6ZbqYva4WT25Vaq2is7ShnptM/OVgrH31pWJ2j5ScjhlFT
7yFrwkRlxBjCeySBuauq1hiNrbAHxrpT30CaTL3Zc7SnXSn4enyC5L9OTYvrBXvjTGsdnKUL5n6u
enZqNFeTqd2jleuTw0IxXU1ubeazGTW51T4+a520TivJfLpqnmb2Nkrbp8fbg+0vuZ2Tdsboas1S
6fTKyV8W81vfquV6En4BPQkibdwTrkfvUtI/c1iEmvxxET6zvUt68sjYxnltv7BbWd03m/Pt/p5S
KlQuK2eFL6uFtnx13X9v5Za3ypnz9vteY/s01zDUy/xV5uqgtPf+pFhsb10r1WJ/9cvhzppZsrT+
TqWtq/KvQ9U0nj882bQJq88fprDUqafRF7V9s351eJnLtZPNZrGyq2zN18/aA2Vb39i8+XK2auSL
8vX71cLhXrd03Lvcf29vmC25V01Zcv/WynZP5+0PzVJqT1WVwWV9T/mQaa79SgfLE/CfYaBoXWGD
RFOmHqC90nnFslbnB6e5llpedVa+GPvmTeewOO/sbWvrvZttfbXb27pp2l+6itxYq6s3yq22vlxJ
fjE3drTVVUs92dvtdW/WO1VzTx/07eVM69fE58YuOOlvOA8TgHsjwFaW9BSnYZXd8k1mef08c9pc
1vNtp7A8eG8edOSd9vzK+lllt1HPvs9vNAu9anl1/3ytt/Mlm/2yd70zrylap3iiD87ah8tm9kM2
M3+tKo3t4vlK9uzpZN7ptJeizFt8apl3ilXrm3Vr3jolrExTaNVOtwpbK93k++z8bXKzM2g4m4XL
an7vpG7m5ufzGblys6J2qh/mz+za/HpaL1+/z62cmJnq2fzl+vp+/fzDZva8Xq+dV4+rWzt7K6d5
tdLderqBHVKYDY1ZTTPEor4mDpKoSpSt34lL+xvG/EHCJJPjvI0FPfSPX9o3cVvVm0/CeCfUiUQy
PsfUjPhoJ9XerZdubgfF/MlqJm0ca9e3jZzpHC7XB5WDuq22yjemvp866Nc/9DbS/dRVpawmjzdv
jbM1rd296h/nrlvJy6tsP3V0VFlrdnKZ5lMfqwYE+1/B3iT+SARFDkaenaRIrROIih7ZTEtWqfzm
YDtV2shca9n6eq29unLdzbWO183U5rZjnClFZ3Ckqd22Zh2Ut/PNmlk7Wdc+7O5u5m533meV7crZ
Qeb6PLNsHWez5nxxe9eqriffv5DVGLLiVszHpx4XOBCJ+3NqWuj2vsyvNzM5c1POrql76fTOlXn8
fu1Lv9S73lNPuzcfzrXklpaxDjfN7eXbbePmUDmfX7+6TPW3q6XzsnZUqTaNVnqvtDPYH3zom/Od
+W8+pH+0w+OpjmCfWSXH6WueQEBxoSMNsJ/TCym7dv2DmtxbPq/vX51V7EPlcuN8zckMDLsmywfH
Wr58ZHVzx4X5w7NB/bC0MihmO0aps7aXAyGzuXmkfdnOttduMlu9jHNeHdw2u9Wc+mTrzM+wIAg9
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
SAMA
