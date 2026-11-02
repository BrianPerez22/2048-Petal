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
PAYLOAD_ID="c448c2cbbdf40148"

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
1RvPwngn1IlEMj7H1Iz4eDfZ2qsV7+4HhdzpWjplnGj9+3rWdI5WaoPyYc1Wm6U7Uz9IHvZq593N
VC95Uy6piZOte+NiXWt1bnon2X4zcX2T6SWPj8vrjXY23XjuY9WAYP8L2JvEnoigyMHIi5MUqXUC
UdEjm2nJKpnbGuwki5vpvpapbVRba6v9TrZ5smEmt3Yc40IpOINjTe20NOuwtJNrVM3q6YZ2vre3
lb3f/ZBRdsoXh+n+ZXrFOslkzIXCzp5V2Uh8eCWrMWTFrZhPTz0ucCAS9+fUtNDp3i5sNNJZc0vO
rKv7qdTujXnyYf22V+z299Wzzt35pZbY1tLW0Za5s3K/Y9wdKZcLGzfXyd5OpXhZ0o7LlYbRTO0X
dwcHg/OeudBe+OZD+ic7PJ7qCPaFVXKcvuYZBBQXOtIA+zm9kLJn187VxP7KZe3g5qJsHynXm5fr
Tnpg2FVZPjzRcqVjq5M9yS8cXQxqR8XVQSHTNort9f0sCJmNrWPtdifTWr9Lb3fTzmVlcN/oVLLq
s60zP8GCIPSUcOjU4hGEFX7s+C3isXg4yR+yv8DBjYvLM+h7qOlmjP6dXqNzVrLV9lkmWerUck2z
W0pVrIvc4SrwHnP3SC+fXhTPV3uXq1t5TU9sDk6sqmxsZ5PZfjm1t1leH6xd7hvW2Vq5O8hc72aT
Z6ebjePjynOvUUH1Wfi586P0vs828KpNbs8kFO0u1oFOzowY/mRcTnGGIlOP/hB8oAHvd4xCnUwG
qcpaczN3WTk81pvNQWqwlVtYq95o94W7+87mdvl0RV9PrOylnM3DXbuRrRyb7aLVd67LmdbOyrqc
XG+cn+8fr9+WL84H2/tnrdSGdqnWBTKoddA29iO3nyGdwd4/fQu5UHWLogfzm7ZYE3THcD2TTFHl
Rw2uUbdMrR5TrPZzDa9fAw6w/zb1EPdKh737ynXncLOspWztsq73VnT78O5cz59VD05PVldXzP5Z
t5mxtjerucLBXWGnq+irCymztt87zjaue7l+5+Y8Zya0cqe6ZjVyhftac+wQY3e8yADT7ni5QX6+
WczXIQ70I2ZzLdk9L56unKx+yNeP10rXtwv9+mBj1+zv1Z2jxIZZkk+yWxc3ifxaajO1fVFK3trq
Wn4hldL2DuX20e5+8ahW2juqXZcyF3s1vXS/0a8kViYN9UvN5hcd7LtnH+o7YaDvHjHMa3nl8Ojk
ZH/zaLW/eXd/d9TrFLI56/pk82j9LFWpf1g53jnflFu3K8mblctqqrXT1pLyQefiSKnpyeO7rY37
xGX7/EyvXjav+2cXSkm5OR4/zHe/qkGuK1Yf9rrPOaH5KmCY+dfpx7l/e357OejeZFe0s7NG+qSx
qx2tbWfLa/VM8b6ZOyj2a/pl/uZkryefHa1bmc2d6/NOIusUti9TqQ/VD42TSi5ROyrtbPT/O3dn
ttwotqzhV+l7wsUswcU+EQwCARICgRDiYkcwI8Q8Q+yHP7JdpXJV2y7ZXXK7+8ossFda+elfQ0Im
h6iRqQNBnF6fnD9Ozo8e+RjQtxPzdwPfIb9FyucNpRhzhJykksFjJ1lox/3aABHEsv2KBkpbO+Jr
rzIbb7aFiFNXIyUjYwxEpse2ODXssekiIt5yQdLzHK26g7WNnf5TSPlDAAeV7zv1befmH2ycMf/Q
vpo0LrrbYdiyO3FlEuJZpr1LMyNaLOSMCekt6cgzsT5gmzQKdo2w9FFrD6V2T82BLUu561W1Fiw7
gFA5UY8myfIjTUTYL5dhH8T6q0s+CPbt5PzEwhPQbxG0SOInmY7h6eSszWZpLBHSoaujOoZrs8wN
daMeKEDQaghEElQnwVOMIXmPpEXpV1t6YMUsPe1YxlZ10Atkc2+ClsW8PmZ/lKA/BnJyzNrhhhuq
S/9nwJfjq/E6ioNTS6txfJmPGcmwyB1f8n1OLHYt5q7KGbEgcQpHpWSglG26Gw8dws44qN0JM9w8
1vxmBUe0gqd6lWdOmAOQw7m/XGF/CN4HZ3wU3Jsp+ImFp4DfoOCjI3XpeJikmvZNwiOE+XoJ6utg
z5o0h3oOVq5n9QjMKx86mKMNSLDrp2iekWbo6chC5dctFqmjFdnZXPdVwjzxBfZZVl0fB/loo8hN
Gd8buCC+b1xN+NDFJluutqXCJojXbTfsIU2jCasU35AOXVEE/EHSZN4brRMFwRA2K1b7cStJAmoP
ROCIuYSrzuAku+2pl8D1/gAT+utT8YM3/l2AkzzPwhvr+KuNC+av7atJt8sAptM1T5SLbvKqiSpD
RBN4EEIADGSX9MwmJWe0IZPtenYhMTlDWNu9gItiJ3u7uHGPNM+puNLSSbHYmGoMiKr2Oulvbvl3
wU6PRT3D/OSmtL8ZueD+duJq3oIdb9INIIkSgjoxjnicJjPreoJVBWbP47bbr3YduofVfhxOo7D3
3cAOMgHH8aDT+HIh9fHaNFb5yTXwMVzucQcVndd5Xzzz7wJ+y1sWTyxcUL/xtkW0NEAL2yyCdV+s
NkRVzJkuiWg2i2sGZZpGNIWIPgI4FeMVsKa7EfPDcN4zjg+CkVbrwLZjKX5eE3BDdcUKMakF9vq2
+eNuW3wc5OpYu92NMX+1cQH9tX01amTpmezaI/l1qPOVss/ESUGolZafFiC0wZeRvuv2gsOiBy9e
Lwix7zQmk3k60/VI4hc0CW+saKpErBSE4QRqdDqy7Osr7m9u+XfBrlESGm6K+sHCBfRD62rMU1vj
9TCVtMiivjn0XSzDo3ra+gUlh8OCTMLNHilXWVoRx9NaL6JTHJotvNxCsIRxYkhE8GmxYKmSdS21
captRmPw65gfHfLvgny70Mil/wvgt4RF4Org6cXYQehxdDkYoM+SnFSR8TYttWnscqnvRYvZd8dY
YhEZN1tIbwyGAAE4sPelq5BHmtlv0jiN8iWJeUsCoQflc4RFPgJu5je3DXx9N3DG+71xNd99fkTW
5mTG693KdYV+na3c42gtsYwR1sVepWoII6WFv+42rkyxxpBDO1pQlUBLBxpl9pLvZecJut5b3qpb
uVPhQ83q9YXXR/F99MaNAd8Xv7gt4ScWzoiftK5mvFzJck+SQ90NMJJw9K7PdWJhMLXWbeUzUrmI
rbmjZCQ2d4hQVCZ/uR9lI+Jq269cKEP12tkIcrdVEGfULXwl+VP+Oe5VfHXHjSHXbZbXN0R86f8M
+HJ8Nd4ZEMYpVwQjRC93uF4UzamNCKDt0TSrurAGPE1RTXXTof7JySuvzybdWDhYmQmd6h7MchZO
p1HPcov0LB5gsdCupM8h4Qdn3Bhuf8xQ5KahzScWzoCftK5GbEHhRvfmuNGZ5VjOszoh0am3I1ff
bsKyayn3wO4qoNt0RLuMZE3absYdOYNPYcOwsE/iQqlImiot5w2t10mmoQ1FfJbnQx4c8iGQbxja
/G7ggvhNoU1tb3IczKyQrSGvbaMGaJpJ+iawtI4NmxUI8mCd9pSL54YE7pQW4VuyEextyKUHjpOq
NES1kYq1apEEkH4U4Y4IDq8T/rDQ5scBvt0Qfen/gvctQ3SjeiDsB2I7KcysYrh+0a0a9wgOMufq
1ilLzZokuAMb8AusV0gm4QySyEapmkTJUNaRx2bxtIq83bg2MaVWKSXuhc8xA98S7ouFqJ4njH6B
0bcTft7IY6mwb627x86vCHqcTg04z47ibB0ulIGDnIOnzvzGsikgUDvWXUnuKbp/XlfdTHYuxTQd
a/EMBe2VER8WaBltG9zr1kC7GwMmnO0khnZuUCvsyYd+zJE6f9C7+/yBbzXq8B/rKV1R5Qt7I9Gn
Vfee4/ljHb734LxYOMO8HN899PtrkiuBbEEgsQ88xtawzkqauEcOSiUkrnHY9Eck2DGzgcbQpPWZ
OBwMLAmCDWMxzYE7Lme6vDGBRpXMgZzrmCAtnWhcLm7wnP0virXhN6f4gOWurY4vcDwL58s7snee
t/FA8tK6e+j7ipv/W0ELGSFWEAhsnL2m7NeLI46phrK1FsOpZclEXAE7YdhJTW+IFNHvYb1y4Hhd
w1vOzGGG1mULxKOCIdUulfZeXry7Cu/vyvN9VcLPgYC/zN5T0vplO/e7lR/P3D3YuCJ/dx4HAD6F
tbXsZRFLOnUO2v7kjCcok01gEo19kS6puXGoF8PcnpcVvg1xwWlErjyFk48fkLpqS3i7OxAqgc43
3vzIvRHIda79WSYvzTzoO/KAXjLzmKr2vX33aOCKWOwkbwHNUzVWnFwizm1fIVQ1Z9SKkNvDgHiC
MDYJrPr0wlqKZLufRb5TV4fQme5rvexUO0f1PbNu0sA4/wXc9JsVdYN0tRfHj/uikPDLM8/zUxX2
Bb5q1Mrs4nhX1WAypfbd90homL1UA/5+FnwH1pft3Edg/3Ty7sHMr+HmurkQIhvT6tb0dAoTxvoU
Q6fCG5DRML3ovD10kQ4d+GrJBca6diJdsXZgtlZWWL2Xcqyglylqt+7KLvmEm5EzTx//uZHY/yLI
FwT643//++O/yPkbgNwf/d9/EPyqb8K5df9ez6D+Urt25h1fKo6BfHnXpuHP/d8/lHhp3D10e0UC
UIlgdImOKX5eOaSILDEVOppsH7vzTq8XerRls1OBsBJZwG252gLssq1SUN7oOSTx8+VhuZv7RSFZ
Mboey0O7poPZu4s3vSLnpx+3sZtHx0E/Lj2qNrtP/7t/S2/yVbfwF/LNWXx/EG/l+/gPPQ8X+qtw
z51/JXs+unvo8Iqy5KdIUQpkqkqWUikQieUomxpXoZJuhp2FLBTnGQ/DMQrPO2FOt6chbOZrc956
PdWiUwizbqHsoGpCDQPWfLvsDhhwowqbb/Z3byenF4dT5Avxl/x93/mjv++P7h46vGLg5GlgNyTh
3g3VU9jnBO8u+N5Pc51rUE7YkLZjO3Rq870p5LRkAbw+QoUCE7jj8+F8lRwjUNaWmoGYVA0n2ZTl
rnZjGV1GpZ+GoPPvBXbdlF8lNHuuYsNvQXr/KnMv77Ov1TVeq0b4tKD5O0o1PGfpUtXjsQ7hDxZ+
DRzwIA5bS2vG8Y2d2PPkrFUxLaSmzJK1kkQF1ABIeUlhm6IreSLdMgXvSalEJKCXQEiEMAy77PcI
Vx6TTB9Zl8rK+I0C+4Vr2wJ8/HH3NDPUt52XdlHYl9n8yat63uTdl43db6eev3L3aPDXzgY7sNhR
ysbtC6CCl3HshZBLG7C+IEhm4qVKihAuPAlqj6i0K6xTQ9kwWtBuLK1hMsyMQJJYmkEORs1sun+v
kNso8ufMUn0P0xcDkr8d6ENo8rnTV6OcNWlKgwqOGA08m3Omuehxuz0udqHeWNPcLnfhflkeTD0X
dgtoybGHWaB71Oj7pziu5dNsAxJeU2hSwySDFsPpOvOlz/IA9V+G+XJs+feiHJ4DObwBI2GRKrZN
88ZI2xWWJJuuNAkYE+XjRoLzMqc7IEx4XHKKbbA7jkU5TQgYDMIkYUoJI2SCeTpuE3w9pYULgaZy
yLn2c2wU3g3xisTR30Pxp/TRZ85ezbHIyllU14Pe9O2WSmaSdwQBgT0ADixEp53fxNHu5K0oSmTq
Og7KZoVsyhHkTNEQuYbab1o43yZUJXQBdDjBGxIZkOVnkeNPSYZvBXlrMf6QHvqnc1cjpH2h4q1u
uTY8MQRlII+sgBt7Hgw5DJ4R2CFiY6Snu7yN5yk5HRW4sdid3E/m9ngGje4FKQttBouOO7o0Glrh
FTz/HLfm3wvwmsTP38Pw5/TP505fTTLYciaYl3IIhnMCYqVcI7ZCcHAtFie3Lb4BHc2XYHkeqklM
c5U+iAewxBcm5q9rXKvEAEWM0KAN48B4gVJMVK8o2WcR488Jgm+GeWs5/pje+eeTV2N0tIre5gUP
lwC0bTf1HpKbg94IGzbpZArVUd8Z8H2mGp427IXc5NIYqCxvuVt62irkPAtfzww+9U+HxbzCtmte
NePgcwjy3RC/J1OGWXu/9o9eKg/6e2A+Y+871GcuXg13RQidV4lGk8zwEM6nntXGmFd4gEuPTsR4
3K5PS11oxFUPaSiwiTF14up5FYT67ijNq1qJT8zK42GQpwpuyMfM5MRfavRviJC+A23a1smHsv1u
8Dm4369eTTeaK26ubiYGheM6kgsVI0TIPtFkU4dRfNJiLcEpa2bWBq8PRp1k82bOYJo69jOkkQ3N
nhDNX4YnzNCRxcpZwXNa+/Vy6B9B99W7GL8Z7OVOxvMXrsYpaUq7oeVlvknmVG3E/gGWLPdIAFBb
QDtM56jlDhcm+iATCmDNXJpkrRIhAFEdXWs/D2b71coGG22KjPnWG0ncMY7AZymr8BuA3ivkw4je
G3se6f2Vq5lCCzCVUuMEK4nqq4cxFHo1heKkjylZn3jtKNNrpeIGoPI4notBhBoirJiZvVuNdaMK
pWkZrafbfO05bDEdQhHrtc/ymOJfYvot//VjZPrE2s9Un1y6GivX9XNvo7mIZpO7zbHYWoYATZvQ
WzFTHRsjC87EdmlOu6Vucu08XYepb4IQ6DAGLbQN7E1Atp/QwsD2hQaqIWQa2fD602t/XzLuO8F+
kFyfmnsJ7ZskG0+DYyztxdxAOUCB+oU0342e2nTdXO8DrxlwIhZwEDW2AxyLw1hlQMn1gZmWscEN
SkQnwBTb2xqwxDUn9vPOW9rq65L9x7B9TG39GMlebP1M9XLh+q1q1FRTQRYYHy9Ewz6Gtl2Q4cwk
M2U2hGIjHVcrU2PDYgETS7MNKNwug6ThM0CiynVjWFtftIJNZaYgOOIHjSLpvfM60r8rx/ZdQD9I
qv/P3ZU2qao06b8ycT8OYyMgix8RARcQAUUgYu4Eq6DsO0bM/e2DSy/2abu133PPPe986QYpsiCf
qsysLDLztbOPIX1ompZtZDD4dD2pSWuv9GWgpSAXdfJ2uB0BRkqN8uUEHQnWHoFXmk2VZAQHCosW
1dpiIjrPKp+lQ0lvaGgxkQXfWS+1Gf25tfRvgulzWPKvmaZvenuP6ptL98NqpBJjuybhTA24k8ML
kKGRyKYqqX9Q4Kbqk/WOcpsslUsswNwERAeKt3O9PJgHLixN/f2Qg3Z1UAxoFFs6iooVYvH5muaf
i5H+JrC/aLq+7e4WtA9N2ZkuxTW+D5v1mCblqJmU3YT0i1UIRCvVH47ENTmylHW0pqMtBQjLms+S
BipnQ29KghUwtUh6xKHwvqDkpbpHhVk0nKWfT9l/G2zPIea/Zsq+9PUe1ZcLd0Oa2Zk3cAAuHbrU
Yh6PlwaVOhPVFCkHbwMcX++DAVoEMhXUmq1D24Rh9QOkcjNbKzQAYKTA5VBjUpkY2I8QdrwBF03+
uSH8T8W6Pwjo5x9S/kw4m4+lb/Og5K05nJcHWd/VrCYoGSRy4CSI3Ynuj0AuTxdU1BrroPXnCTnj
TMzYLmXmgI9phnL3cbQhdZXPuJoKqT5hwjod0fZs/5vszPzLQP4iidvckLbNo5J2MOmrE9eGldJl
dyq+2K1bp3RwIh/3zWN1FpndsakAMGgkVxy2WwyIBbnGndwOC4bWGl2tBZMrCoSfgfuJ3N+RMr9B
/q2x/Doq/ecAeR2b/uOPd0MY59JENGkUTfSE4pwi4XMm9PZG0uoRuZ7gSCrNeQ+IEh8x43UcYiXm
2cZqtZSbYBqpTT2b5NEwg8uxZx/6Cq7FTQP/Hpmx34eoPwSiZ2RhHLW/YLf0h96uAb26dDesQxRw
Go1uhTrTnWVO962DP0hxFQ2a+dKAISAIW1IPalOjF9OV2F9H+8GEFEkmARNg7qmjyagZhp2hpEra
TqBQEqo15HfZNX3DlsfBfRsFHubVrZidn4Pt+85eoX1/5X6foKAK1txbiIkwWMaAFhkRNjULHsPl
TNXNbSLNNopWH1CEWqGVM8Vz5TCulVG4kTF0gU7DCqjniKx40yUZABQ6VtUF9bu4769jWh/E9BT2
/YsgfenrPaIvF+4G1NoHc6+/nQl7UhetzcEXDcTLdo0+XwBLaqLj8nLVsrMx6Y+UrI/qakDvWIZi
8QMz4w3FN5s8PJAOxPjhYlCCk1GUD4HPp+o/FID+IJ6/wrS96uk9lo+atqSzrZvZ0hqa1TohXLEI
8vVkz/ACv2fbYLPGt0HLAdp4UNUsIBpazKoaJ+di7KzG+L6KOT1TAn6zULzVFrIdW0MpSPk9vv/7
l4H8RfOyuSFom0fFrDTTo6xebXb4NIXjeFTHrDm2KQwtxrVm1JHDWqTL8LNUWWeSzlv5fm9g0Wo/
SlQJHOAsvj9ECL2B0zKhm8gYtRBU1b+HaXs3ludCaafiYP/zP5dKkx8BiD/B3wro+YF+h9qbs96Z
7h3l22MxyfTqgNYiM6v5cerkjqRuKiRL+crbJqbKuEq78cxmqA7wpTAlMR8EbNVx6VCfx+RWMFa2
Md0uZD7lp2sMaqX28DfE/n9UsK//dSW+902u2HZVUvA/b7d7WwHws2avJSG7ZpdWn4Wr3HyYGwMF
/04k9MedvI6Wl5965x7u8P+6jA2r/hAWSGWp5S2wHEQ42K1NMcJ1mj5AO8RWZodzFXfiPjGgNr44
yO1mX1R20DeFZZmohTJbatDwsMfoepOuRSL4JUWw7wxSvwX+x7AMviN/P+ziFZQ3hV8Hd31mBC7W
htyyKN02o2lCaFITDyTegcFU3FZtXEu1wh88zRtRwsLcEMt1vh0EnXrNvK3urR30gHAI73Pjsmpn
IGV0y5x3qZb+tln8PnL6J6H2ZXlW4l+eTG+KtL77pXemf0fUw7HUt4v3t6uxPtoWw6RoZoQTjJzR
zuIE0hKKWADD5WxX7HwIoGzWnGxDHI9DiM3yZZP7NFCq02Qhz7HBWjOmtajag7+tLuaVZCWe7sqG
c+aY0zHSuQXGMVAO+jYYZ9IdBueD3pna16wPVq3AR4IVSqODTVUYODisdSqjPaXfZKnor/WRXiiW
GXKTkTrnogWREsMKrOcSA4r9iVkreWpOWSRGJ+OYCYa5XfLAg1LsS74lWZz0PivnCqFP3RT6tv3w
Sv8YvPhy0ruQvWNFjZl0a4TKcDdnSWZEh4EYObm0ZAUxlWFgXft9OoTQxomEZmK4sFdhHKFRSoRk
S3s5E/yZu/SpiJtKbVUrRsprCD/9eTkxzq92Kq1+i4HEN/NgvCF9yu9yrN5+IXZHkLxLp4m6qurV
EGq9sLbduJSLBezJ83pVtVJOpAnnkuM2S8F9M677ns7jm/1wvYUYmtsR3tRsARkE9iIlSwyDwFEF
i39DzosPRuG1BWTl+fHCSSggT/AjMuHMMju+VXrnxMxvhOa+o/4CTnd8BuiOYFyedpC1E9MLTWHU
Q6zSm279k2wxvQoyZhEIIk4LeeVNEcol1fqwdAVCrMvGHvQjJ8m1edq2ihitbNqtMCLtMOasefZd
ufxFMfvrMf7HnxBxr8as/MLZ5Zeg5d5ns2Tw9C3b84MOXoKkz6e9E+WvAdmuy6FXu5uqosejUbgt
yLgWqXhX6+EMDS0uQozSdajcL/xdjgAuvMizZRGQm6mECUs/DXbBEGMVam1yTn/SptNEMeK/zcC5
rPcuevIj++bCg85giHI3zsILN3Z508udwH2+GX/6qNj0Zzefks3cuv24rP8gPv5GMPwPC5y3r/U+
U8bpCTLH7YaGd2rTaWH84UD/P6HB03H8nvOiQNdppe6cEMdBd6I16OTROdcKeqRzOsJeju61K42o
7XUCMPRvGpNQJ1Menxxv6J4Ks76c9U70vp4S+LoK50awkQqo3u44SMrYJpZnG7Av6szU2SYOW+ns
cL9LiCqTShRVV53VEqUpzCZqOCw50yq9JkSmqToURgNelyAT/mkJA7oXCo3C8m7w7Jgx6fG0h89E
zww7HZ6yqd2R43DOSw6zzvqjQQGMAWG030nIXEur2Epg1ZAPAoqurREWbkXeRuamRQPhZtVWioKP
wUNu0+YiUjDD0tdlsfcnolqtMkh6QONOZeoeARJ109kI/IPTS4zCu6jV/rUISXwrfubtH38e87cM
Hpxmd+bTMLJbycOOE+rx9HgdvSNy2bZ3uv9r0JbarmUEbi4OWxSfVSImcjFhk9tFmtcewUMSP9Ns
0S5XWGNu5O0cwZagDlZAQhBEwmPDHc+7MqHaBINNob0IToeTNfvTbHSjLOKkE3l+49xy2nQLEew7
jHpD+cixN6e9M8mveacI9RBs2RVbL5fbA2MJ48KqsINHL6fOdLOXZAfqc3Dmwy5a6fh0jAdUge30
g8SgYGluBR3ID1prhzSDklpOortGhYqvxINbRvY55dyrz/R1/HUNno3F4zak1Wkjxyr8ynkzurs2
ZRa85c9106du7INJnB+TboB/vNz2v//1eX+Ff0xT4xaf9vTc6NTH5VXArV94pQl24FwDfnfXZwKf
dnxucuo2T+Ioj7NudPlvurgc/fetQXqHZDGzuM67kRl0g+1ZPRJPwytj3oj8slNAwbMGPdoFSL/f
hwjoSgK5WaftuyH+tDu7A9BOAg/ei6gOs+49LnSga0vkAmCvMoLyKOpe/EEnnf2jNDP96Ppt3s29
Y4MP4bnb7jgbBc8Z2aAPJOrnVsfljU7EiJNT62v5ahqdrdc9VO+CzRcZG+EnqFN1jzsbb3Vz8lt9
fKl36euOfbs0I0IS2k+rdoasNVQjNdw3CU6OoXE45k0+UlJ2WeTzDcQ1BiMydTSkTaStUthdz2e5
VBnqLiIVXELjPKVXRnJY+A9YIWRiWJ5zzGL2x+3R8gmj/7A7doFW4D9Zu/xhNXpv3tPuiYys7TlN
0T13B+ctdw78LVPyB+pHZN//dkohfIdZSTkegMcNmjo4Nyu5Saz1XcdDkkm5Hk9IS1o7LQcr2tbT
azfZL6YtCBCCte0byLqUY+1gVGEb1CW3EQUX8YL+rlPCj3p07mU/8SNgrxrozR13iNvcj+wjuzOv
zO8B9Jjq9BaKRz4/btyeSR6hOx30TlS+xqsVTXUrgIKsK2N4mvtckMUAPnExESLoWTaX6dyO+cPc
Wc5Vq0C21ZiIOUsQ7emBLZMMZXYAPXaIjkTQWNDo4PJJU/38lbHrB0GvW7Bun1eQR43w6HS7x2h9
p+c+9mbAw2/sub6lfILp9bR3Jvk1WntvFc5LdMFqq7hILS0mRk4N7wcSSQ+XpSrJjKSycCCOMooW
J60jgpWKbed848b7uq1HOeerOh9N8nDDs1ASCcQML79yLP0iq+yK87/WMvte17+LZfaJdvrzrIiR
e820K3vOOaKTxVGviHuWd/QulOHlBvRpgF1ZbMc51Mu6O7qHyV8WltiV2Vcm9nFP8mrg2+aFIvLR
KvRHTfzOCj0q3of17p/Y2YNz+kuc/g7P5tvFioOujbmjG/lrwWEZoRNY3ev3znbcx/q5/43kyleU
O8lxdX5KwHrHloEoyJVTeR3ndlutlhpMqvDD3OYZIjClsAFKkW1goBpbwHwKOqMob4d7v0CNHYyQ
W7ZEEmNQDMltbUbqJpUBX9AA2Pi7ErBid/H7ahjf2hk8D2z4cavoLf0T019Pe28J3+F8djdjjG9S
hUpJoQ6Fsau7+NjyNlWQkYAs2QsVtxzO3SKNlDponu92CYPT2zygwH7hc/5iZexsY7EAU8IC0RLE
2QPxlUn0/19oXw2A30ZoU1RvpHX6vP+J58fy4r1vG7e8Psi3ahY8Ez2O1cthD7mvMgGurCDEDXdx
MU9YP6E2wxktkmVOL2mA9okowMDtgBmR4TTss4LA8aUxXIzHMTjeJH2dbKgMsZYpqiejNFyS4nZs
G/Dy528nvvEJ//HXdYWNk2q4mNTHa/3ra9sgNo9uAic6aY2/0Pc3+3nvsuJ59pv+Bb//tKRrc6Rz
uji4EuT/8ZHj9a8fHK+ZY9i2nyWXq9/LY3z8OOGD++5ZtyRGGYSdHZ1dzagfaT1/zHjbW+HmTtXx
Mr8wCrlr3/ZlgF79eg3Nx87i79RSeUP3WNbo9ayH3lc/hRSmW1mknMSfafUSIaWIbQBUiVYlPBlp
9sFklwPU4WqoypDDCKl0zmkdG8qpoReZlmANQTnjWx6VlmK2Zw8DQx7q8c/3+L8ZlX+eR+XDY+ou
bRuHodE9wS2ZNbhy0d0ts56pHoXW83HvROtrgBbCPCQab38gdwemIUZwhQrkZAWUaCKJFrymDFhJ
hzuNAxEohmt/GDYjEuemTI7kCqrI1GB4wBLac01+zVWyN9/B2OYftWjiqONocdmEPZrxn5iR31AQ
P5A/cf39jyeD8g6lMa+SATqcZArM0DOIInMfmpcAryF7I59AwxXT7lcHuNmEvJNi5h5erBFVrdwZ
IGJQ2G/2xaYuAGgiay4y0/NVmCOGNPtpmyudZezkt756R77HvxPJI89OBycHyx18AlcmOLN2cwiC
ooVssbGJ8osij4oFDxnUYj32kxG42tc647XjLKMHuCw0IETUDGyau62F6AdKnm+gFRoVKG0yMXkA
le9+7vrDguqFTycX+OXsUQlyTyWa1y99PkYE/obL60LzDMnxqHeic0fNIGjCzi2thRuSIFnRrbOo
vyRbYDnCVZCVd8hamW2G6byNBkizMYBtgEZquB6kKcdLh43CMRQxL/O1SqzA/p7qFkMJOX3w+5zb
rLIds7zlxD9+zvs4o04UOzad/vdONO4Iw2DrehPVYrVXXKOaKwUMMyxXA40m24f/Y+9KmhNXlvVf
OXGXT+GD0KzFuxGAJhCSAAk0LE6EJDSB5ln69Y/Bdpu2sWXCfeMu3spVdDlxZ2ZVZWV+mTnZNBGY
VxjlK7sJXEVb1DdsiNjBRwkpSk/Pu1wJl2lVe3OSDYJDWE4OomVnP+8ZjF7cDWdEwHc190Mb7PdI
jeCU5i2BokrTJC+Lp0uQ6ubf/nqXDPLu3fDJLtkH+y6pIseM78h/fAHJfVv+r2TPSvA6uTQTGWAK
eW3ZuZng4Szf+evIAlGMxwW4LfpuFHUc0QBTZKMAa226LuqJtLdhrYsyilpx7XjqrbxiP5mg8jxw
T1whSL3cTBSq/4Yp9CZI8wnrwvouzx4Bi5zonZkV1k/jYRARgAu7sjuEKz6es4RWbVhCraPpimgL
YoWPO0DmeRkzNDWhvWXlrNqSSrZ0wOHqce+s1HyNLqYpjZnJLnMNd7FdHw9a82OAmjvOvI/5hf6N
4N/Xso++4gys/uDjp+fv+JqrBQLErgKRFsjw6Y5PzHkbQqlaJKId45Nzpy85b82uQRR4WkQrZweF
DKmD2LSYrB2B9WfKGon1BarJCn44Zg5i0Nl3uuadzfBPuFo8OXl+jVP/HLbrleoFlv48HorrMlyU
g/i2hNqDUluLegUZ6pKez9oJdgD8SST087BLO6S1p974dKzHLUGqHchaMnB0UbuZ7Rim388YH9Lk
GSNulzJmF38oAPfXW+zRZ1y+9CO+w+MHuxy/NDl+ehkNbmwcebC0EnaIr3VNkyZUW8HrvYm2M34d
APVMMTJCJhcjOj36U4jreS1DZJExaBgQeRJe6K1N7ATZSYFQ2sqz0WbHm9PsKw77ZjGPi9IMQ9nO
g7R82OL7xcyLyfcy/e7N+aaZ8TccB6+tpc3guSTcBxK8WferqcvwlYOptl+u/K2HxoClX9P8vRvA
kLVfU30tYDt03UCKz/3jv174UuJyyNooSAsMuXbF+3LxED25qVk2aO21yNSQlV/zPnbKYUK6rVHz
2cqiipNiwLo3xSwGrRwgzrdt5V/WDTmkbTM095+98B65Ca9EL6f0dXh54w24B9XtAcrC1lyXEuJh
qwy1IZJVbJWluj0RlEuiV8Ig9ehZDy+cYhIEEp+Ue2KxxZJyCq8mM4/F2uNi2+18KxFkwDo4o+82
RBv8DBnA33MLvBdX38cMhh+wcl+pnlsMvoyfLrQGxA2E9MTHLWhnNrPv530jKVwShBrZotNczDoH
N0bLaoYfZ8ImSMa0IHfZhoen9GRL4YW2yZBAQSa9squMve+tIWVW68v/TK/OS3j6JgTwQUPHc1z6
rV/ir3eRhH/eRRIiJ/cc6F8vQe2bAEAU2Pkb6PXZXfsBBOkrEMtN4GCAvvy/v32QMv13+dtfGl7e
8QE8AhC7kHze5tnTlcjXYtH4Go3jZYHFSwYfi17AL5Zzg1keV92crqTCCZcsXh2MmM037ponuLTW
ATXj/cliO9kvk6jZcXS+k5Gl2zLhKgNHjPKd9toDxZI7VRG43fO+G/asuMGUfZzm/UhQ4xfZM7Nf
J0/4sLCGXrCpA6vckicMPUBKlfKgRQc71qaHci1pqDYO94h1XE9B0LZHY6MhJ2o8AwOyL6lFUAZ1
ua7NOcmby47PbcCfqmD384fq6TF/+r877RtQHvrQdhgCyrsFjH98aMEP1FF4Q/csq1+zpwu9r4U1
1saiUgaL1M+7eFQt1z3c+KWOHXjYVbKEhhOfL8BSAbaHfKyiZJKkbZTQPr6s0BSrp+bK8hIBtPra
majIOkA3nUo9muj5KaP/Z2DM+C5OYghKIjeb8yYcINBfAeR7OOYHDrhnopduydfhBbU84JRD24Ry
NcBd4q45UWLTi9RVajFl4482OK5GgpBlHCtj6Ayu6ymoc7nHANOxHhkwgoxL4YDGGHwEoTGkicmi
6UPfdb9MqH70Sf9gt7phenLOPsCecxwvuUIvyZTjgVj1k1ZddtEZUHHPZTN+yMS4oXwW8tv5xUs7
wMzANU5sOTw7GaksGs2b9uhXkZK0I2G+EW3Jo/JWLYQSSic5dDqFU0zIN6GIM1OZSWdpDiQ7CWRw
BAm23oaA4oXgspD86LPgUbR5ePDN3BogDO/0tV18Lw76Nm/3+wbflfTZ2LuObjpWfy0I2Bdx0SyO
ei1Qy7WOol6swuIaiJyCnjipkoUesKOtA973GS1Md6Lf26yuOxmTjJRQ7zFnHTB2OubsYmZIQMx6
MtE/es99GSYiB+n+18Y19lDm433jGhuWCam1zZygJX+39tQUC6glAFtgTmAusscmGtbLWxTl3CnS
7Wd0pS01G2Vs3ZEqII5Zt5QRhT5Uo/E4LxF+sVIEz3KjGvmG1j9oXH8/oHc6ssbwIFmdTt+kuRdm
u2bFfldMV5InCV0HFyTFACNCgbaWa01pBoaawEm1eSGEikoCe0qfYY3gj8pRrU+QspIEPlP7UQzX
+Vhk5HYddCugP0KRViTCZBSM8GyHLfmqHJfjP5CC8dvBfs3L+8AN/DNO/3eQvDs5bQ94lW5Jn+R1
+8HTheqASItAb3SnwFKq23cVG+wLB5cKri2tOa7unC2d9N5m5OH5Hmy3QaSLYW1s6BEPCZ6hHNQO
h9C5e3o/OTubFkg8isoNq/08bPKj5LGr/+P7+MMhxnpwDovnztN1fl9wj5QEuaV9ldybD56uZAf0
qRjVLNhPZ9acl9aMW7ly02l7IS8Sv1vMt+Ixj6MEUw22TwS8zEdhYbkqakHTOiiWWF90Qs+T23ZH
LjEbnySM1Wmc9PNb7vWMejhP/8Nf+uNmx0kqJ3X7xFkJPfSy/kX2KvnnyWW/DnhZyxZvTcSjiIHw
LkAOtFEj5GnzLYQY6dimsHqjSXI66eigKgsRjhf63pJgrHd9doGtaSqVjDlzpMo4QxebNqpD+FAk
f+Sx9u//BW9xvp+y+hM+Iw+lEj7TvDL5wmFkWDJh64Sy2XEcjBkejRuqHwZ4qsKIL1piSEiHGuV3
0XFBIf50T8GlTyjukax1s1gKQKSpkuEzR89wW38px3mzyZETPfnnfRc36nmFDn3fb/EdCcVVZN2F
zuIPoRFfqV6ldB0/4cMwich4FrhHD3MIpQvldF8qqbPcCVktT+ldr5QlV9MbCkfGQBobxESsQRBE
hM0Sgdf8igp50mZrMcVEQzW209BiNb1t4z9ke5/4DA3i8yEog/se0/EDtcDOFE/sPf94upIYAPcM
Il5kEdpSxXx3SMTZaMyhI5JlOqDMDuyUm5lyIQIraBOvskOxjGpsS8H0AeAPRDxVzc2k6Y74kUeN
rQ1ItFnGygZ+9GZ5F/x/5tEl8n8ev02e+4SzxVOZHJ27aefIQxr8SvXM4pfx5aQZoMGb/WLrhjYN
29ueD4Rs7RWzCsSYVUVu9/OFBFqObq18TkSOmJl6izJw7WRWKqRlt1KqT8uUgo4zAZOt3kNmZlWo
oxV/c5YPRlYdPkUaP2KfHp6BxodnnPEga3RUCPBeghip1w782l9UCbge43DjQryUECUyJ2quw0KG
TJNtilu8Ao5EjibclQbBq8b14+7oZvEMajetFO8aVKvY+cMJfu8V7y3M+PAQynhI2OR0IcfoXZvj
EYzxheJFFqefT9AwfLEWSaqDOx2nc2PEXu53q6TzAFbi4FzXAIBP+7wLF42skkQJi0dgS2hSSDAq
L3lN2e8tItRYF+v1htr2DieobmsWD/vwP5DFlUn/Okc7H8qgHSaMMAjtJHaDe1jms2J//5H9SvUk
lNfxZZMMeGr3C6ObRmt/klMbx61UpUuNtqFShprrUX4gulSe1g1LoasxrJNogVGHnvcqhNrtWctZ
m+iKoouJNJusxCOiAWtpA4LYHwLHfVRE5lHL3YzLJD6iQ9K0zqnkxZMZ78/g5iq6e+ifva2PSO83
6hcp/vbZBZc8QJp4F3anP9lYj1Y7iDz4NBXCW/eQYIaGe7NskaMMvuLzzCbhGnd7uYvK8TRt6C0R
T7ZaQWR9X2e+dfB5dG14mFCOuOP0x1JQwiQpnCcnrq9xyY95iDxwPbwlfGbfm+nTheKA6sVd1a7Y
fKS6fh46ETRbjrZ2vLXHvZ3xk3k0pfrqqOM6yoy6dSDujwkGuJulU4fNmPOETm5wFxuPt3MdAQm6
bDdywsOfXZ8DrPK3VsZz2bpLFAL52FPx7lj7jd+/1wb4RFB59WSfEeZ3pIQ+9Fh9pXoW0cv4AoYY
8FTlU3GyWU/geVMDB2UCVuV2t7NyH1iEeT5matBBMZbtJ4ykifj+OGLqwKRUYslFPApRoc0h6gqK
Me906Ytj0ymmjJeQPx9178zwtR7YNel2ALcrO7jUirhfLhb8G8EeQYu9JX3m+pvp0zPNAWmFyhKn
rYmZkHOmrOSglg0vn/iIa+xBcpkDmKAcs3lbcSYHxbEe6PNeWyUgZkst55ENv9wfsOWSUKYdi2Sp
s8oarx15d7bGDZ8/rxD2pkIv9vdJja4ROvx1m1zr9l6H5CUSk9sDxPGKV7p3Pn1f868kTwK4Di5n
0gCdJzJ8R3vCQkUWRGm7u1VHeCAp2uvG2FsNQ2enraQax2TeH+IRrLBUU0ozvdTYdgJLRLnqU7uf
zSivPj2uVmgHgsZCkv7Qo3RQ/csbuNe9dxPxffa+kj2z+HVyeTkRA4piao079fUK9KezVUNQMUgD
KqVbuOnCe3m5U/kA5tiaQOZ7BlE6JpmBXdEye5BN2gaP5RpRRqueXqzbQi/ogJnxCTT9edfnr3T+
f27rYf31voIp/Ajs5O8hJmx0H6HwSE5RdDZ3ouLisBzwjMCYsK8sZWmw8AIyR+JuNgkd2j/0GZq0
HteZsy3Z6VptL4s62ZncIhsVaKvNsZGmrbCyxzdkO5FKLpalUamVDKxulPDHMoqi/i5vHnHtR/2Z
N/0TNKyid0+MWVHCTyewQPs565NLp4sSGgH0HFRjVLC5uSHwqO2uZyEgUhpIFDPD29rkCBO4OCDn
asUso7EBc8pMq6CedEUM+vnWF7fln6/YtBtMaGIdnNP1ZBZF4F09/e9qS5S+E59tu9Nl+4bG18ob
m3ES3INgnGExD1TFudI8Seo6eLqSGdD0h997EAuz4oxfx6TV6VLaWmyWK5DLSii/KdHFiLDgNDkS
uYJlLasymN8K3SKg9XLiAsyu0yuK9DcmlWlotWL0BWL8WOGy/2glr3eG66ucLs6R6+yBcpK3RUj/
OZetug6QZwTPLT7vE735rZbXvQA59v0D8Ib0WYvezp+uRAeci2EArc14WUy0dM5BG+yA40K/6Wqp
y+u9koV8KSEzb7rnWLEWSdIw3K4tes5GExSYG1OVQiuM6xuPgBcJq0WZIbLkHwrkjIdYCu+qx/xc
1YJb0heWv/1gaBUDzDEKdFnAajkLCk5NSRlitx2xz44pGyDTndzDrJkFNOacbizw9Bu03JfattlO
sRk25631UYdWsTWKKETVk8Ns09jN8g9lUwyOzPx+9v5cYZMbyiem38yHFjjJF56yjo/bmBsXTEN0
CraTt3BPwYUaVVhh+PPC0YmdBrCbCl5hDM5UwEKkEs09hnRoLRdybMPMds3tHMTeov4BmNrbPxel
+RbPfbP4WT1/Q/cXv8+zoRq+kWOSwYjVgSO5rAzLQo4zfTbWtER1yOmhQgFoDG9IwhbZsjQ9MiO7
iaT0e6vI6rmJm2KEqq47NZhU1XPIVPNjqH4H6P7j5WQu2/tSG/vu6w58ICj2i+y5F8vr5IL+GxAf
W1KLfrWjaXq1ATqE6El4AtJ7sNMsIp2c3sxqMjqiur7XvVSHRhBdSMXx/9i7siZVlWX9V1acV46L
GTHiPhwRlElBQRwedgSjCAjIpPjrr6jdrS7tBlfv4dy4T81UWW1lVlVmVmZ+KZ9s24HE7pMy0aQQ
tr0BEXVjUncLiRvTZNP05E/G7Lrw+LPI1ebLwQfZaszeb04xqzUWgr1ps0gaupmBDzvBekunG2aH
E4GNtomNuvSZOegxBjjZj/qlvRrlQdsepUFvLnf6tAeKZg7NSYEph6YtI2EW62xCM1rD6L3Px+wz
K/dcH+yVIXszct+vT+HcdcAL2kAxZniIWAImnimlTSpAyE4dDof30Zybe+y40zHHmTD1x9utBPsS
KPT4qbOc5xTWdsEFFdCu7iIs6lrTwTwk1zb0MtxPA0P0t/383vGv6Qbr0LeTrM4asU707KmSh722
QJxpnvh2ujp5JmosDapTKsffgIcb0hnztEnR+TRcoZo0FVKrrQCHbWFI6nowZ539HNsJKKwnFuBG
o7zw1+YQRBb9QxDTqy4l2YWgpBQ2APt/Z0Gvj6L+j0aX/In/RF+YGBfwitbbVetMqMbSywdCr9ed
9gUpX+7X8dRa7ODRgeNUJpXNVSkNOqJfTPgiFzzQmByMfLKAupN5IULxbBCnyyIkPT8HxKEdI/YU
Sm02Jr/SJ/5vQ3q8cbh2r/+QmtEfJucfd46AH1+jb1zVivPePkEaBwJ/gpnx5YxqrTdV/aVnezT+
UtTFLe2r+XV+0DqTrQGmGycAD+EU0tcW0+6ctQV4UXII0eZBi6bd4ZSgCHNdbEhXWcDegg+p+f4g
0AKd7g78JhPZo5bjuSHtbbcxiHUyst8V7e8PC/4EQ+VB3dL3A7IHLqzL+L4LS7uxMxZ+csbXBDOl
nvnx9qufJhJivyU73vW67KUnS6+GyETc0ZTYrriovUUYaWe4BjnVg4UtD4tFxNmTBbIQwsyK++P5
KEqVHC3EJFwPVhu2IwkpuO36TuThEYUGNtjecKMZLPacf0iF6OYr8z9kjbwv6H6OwW560vDujrt4
4X7AD9S9JnKO/UTqOPHehDCIqsn7WRgO8VJR+gf0r0T/6ukpRamGkRPJmTrEIjsRgel8swc6aJkt
tRGJTJJgAe7kqUZyNr3vJwfOm0tiH45HALMRZNHIjUJgVYTtIdB+nva6LLIEeoJGSAfwv1Y7+YfM
gesQrkpVeCVQ+gf8oMjF5xL/FqZ63BmqsNtb7eRjNlTGE3SLQZal+8smRt4qLaW+CS6TGHukq3xd
9PEuvvj07Gmpx4f/cOOm51/TuNnlt9ZrV38pOfI4s5+dJxEv1fe5JX21gJwftIh6tX7YsZEhpJAH
PbzLHwaAucy8jl8IVAft9XuWWEQreNYXHZgG9pthIQ8CKs38WGWWjoAD3VHHdfjILKl+b7TelgpG
GvHq8A+BxfmvXTveWJmeCkBGybWOSby0ksAPwf2abJ7Iz0Zmxq//+mPRf6X+4JM+rubA3ZvWqZ8a
bhSG7R8MXJjQgi6teExdMADklXzWNzyx8C1NyiFniRjEUJ0dou3SwkQbIGCdieOZX6iV2rmS5lhX
FeFd2uXkoajuiO8/Gf+oPP0rRG2FLN06Nk1sU78CKWqea9qE2XeG0GPj4HcWuesOrth8/biF1Vvw
4NGolxJ5nji+ZtjzAaaQfF/tZHBng+FcL1w75GEmWngkK0scGoe7oSMALOoVGERamLcD21SWFbi+
V3BuzUairo1Y+9sKWG9z+/iLTqFJmZ76z8z0l+Lx72gfx/HuySl4uMYh8ijXR4pOOIGg4ryuLMYH
PvIhjD8c5b7XJfSBW+CJI85QebXtAkOk58bLcdjtkS65xpZ9n1LIOT7Z+jTFdtsJ5toeKnS+DeD2
xTXcsZOoiTsq1rPEPrLjs352u93Py3dnN1jDPo4KZJoHWfWzP+vmTPbE40t57Qbb0XNZ/CzOFCZP
oWNNRfAtvvQcWHom8rW87RTA7a54xZ1AgssUMt9NnFzWRjDAHuAMWhAh7onJYGz4BpYnK5kBoUlh
A7A/pOACjGYrdrXBZpypAet2H4lVzQOQ9W+GXN+HTJ/cN82zwmsf/p5HzIqeVp7+DYZUZN+Zcryu
zRh8g4VjIQaS5cSAOuKIxTuDIUbtVbeD4DBYBobAGbHdVuPB3uGBo15JUKIvUnPO89LYWBkhR422
AYeg2SRUZyqUhtNbxNJvY8y1E9Z07WpQz/rUcW9E61g1t71chRSTN0GUX3EwsZ0ja54d+EGv5fbf
kH7n5OW+BdXM7D8Q/bbQMTQSZ5zUnvRixDgkcTmGBv4OzsWoZwedOaXN5BWoehOvgyk+f5iqA0fS
MSNtr/mCmmXjATTbtnchB6XlDmWovzvJ+8YD++wov/lR0gfZ83Bfbk5H+TXOk8DY3q4pCgyh9mo8
ENOZzroROnOKaTlJzR20Wqgp0x+6CWeD4Uz0F7qDK4aw8AaLbTbRUF3elT6/6iMaM4xg3cSMMB18
W3jqFdrW4yiTV0DW3ohexqu6rAuy5koKRHaikJxY+dYy3GKML9F2F2IUL90eiG04MR0nHU5RrIP3
c9XaKhugbbg80uELTkopmmFCPcRpOe9kqBp1tEkwPHx/3PV9bDXyUmx1bbl+Ozl4oiAee2+uIl4+
O/HodNW6UPqaSbQHmrPOgdIQfeIR80Nvnw+4FGWUpVBAiLfehza6Jbz+crFEQXUFdVYsW6yVIS1i
vmS4nXir6K41YZmQjnQZWYXkQnS/n0nXsAMP6sz+UoHlVOOgfedHuw4POttX7ZsN5g3j5GiFHS2T
4yim5aaKLEhbTqCv3hvVSc26OiGqQlzfbpvK1d9UzeSjtuiziKBXFpITzZOMnq5OsUB1wESJ8dRx
ICxaxmwK2QM8JtGkL7qsrUFQvgIXTidcDglHtKeJvMop1VfHkhV3Z7M0Hro4ri4dbUzL+ggdjXnH
0CbdvfW9+OrryEvfnLd3dv0rW18UBPmzRRz7SbRfSEI906zG/nTROpOpEUCRFmgkmAfcW0lj3vbA
uB06O0NjrK5Bq8CBkGQHVHoWB4R9YIswoxiKVUFF8eVu3t2w5ArDN07CrXmbKbtbYaEsIvHluONP
6l1XlldVkP1os31MbrjWRH0b7X9ZFUr5abKeHzWdq+d0tBvmx5u37eHhqlEDPSLU43WrmrqHjd56
L87fWoX5eSbitz7//1wYfWHzFUJEy9aN9QMJ+rTRuSB+7Rb7mt/fQ0zUbVCX/i9wE7Vb1O3hHVKi
4kQ1sq7TsN0mT4NXGn4wv1GbqrsGjS7IFg27emvVsLMT2kXDrs5tGnZ0Acto2NVbq4adndA2Gna1
b/zP7Zv8Y3dYHLW+P2oMmygsG8ylK3yO1iYtzAaNKqiOpm2ajNlHi+edvIT0m+RhpVnqQWBfn0Pe
O39f0JquCFfb99Xtye1bQ3/CA0wrlxOSEJdgQO+X6oTwtiLZ7TOIAnF9cSgjRNfwUlHr0nvWcinQ
hAbTlAVKtDN1emvUOhxIKRjn8ibUeWkY0ez4y/TX/3f7Pu3mt9y+NZShX88i7sMVn8vxtY/tsaML
eSW0/Z3sUYTfr1tnYl8L8FRS3FTeHdqjZDjduhMig9yZ17fyQjoYWdHOjhIJgy6XOJMRR1NhSM0s
qLfj1UGhxuFKCza7Qc+SO+AyADMtobdmvjj8uX7kT0bY3hSfnKu+4gw+k6yG9nTRIup5galJWyvo
nsZKR819TzGz1N8rBM0z8HYSGm16f5gm0cpow71ZpDhrk9ov0nV3YAFCAG02W3AYJ4NO2U0mfpmM
96pEzL1G7pmbShC/6OXv43Syn8939Yqb3AfrPluMXxDja8rVeF/f14UWFQYeSC4wdI/i+lKjswzg
sY0Au5E4YKficOEovkTzo7E3ontoNIPlrRzth7sIisVpOhuCU2ZwkEbgaG+z5Y5xRvORjGoNzFlK
oVtoqxfoefoRmfFtfts0NxP9af4V+hPFXxHwM9FqxM9XrTOhGt4tN1c3xXKW7zEWnkrhbEihqQ+l
ht7TpGi89AoyhxM6UjWIVa2Bvem4fneZBRi/LEkZOWDUCgpVYDG0pX6pJdjBHODq90cm/8dL1tbK
3tlBUNWWryQqPu+e1UEHeou3dA1M/yB2+VE1q/PyRFx/dqplUHnJ7p1k7/kxj/Ly12FZFRE1ysu/
hvyEbz9IWxUbEkc/zovjQm/678c18M9ODXP8Q37O8/5y++9fvmi9CefVZ+dnje12oopThbFTRP5P
uF1Lyr/yFD47smiuAX7R12lSfPrFGaWgRjhqBs3CudJxVpa/4kxbtokJO/LhWZcENrmsE6bi2RNU
IwWkve1QFJyoDDqB4zZbQAd4WXZNMiW0oiBprpw5BAkPuxn0V8Co/nV+0UxfB0cbwnqe4lRh6MCd
xky+Inxk6NVd60ywBrhE5MSAKJIMEAsgn8uivFppXU5ncrfgDth2ZDpo2IXnIRKBbcdop6C6iFl3
N6ALeDlFZZ8K8qmm90m57LHmBiNNQZz9CZ66o+kSmeA2X5t+K0hOZtsf+I1pdPxKT1aXF3eQdaYb
+WtLP68ptwdaVbfXWOJvSu/1+xNg9nkxvCmvc400eMkPun59D4FH3P9bv6I4XL18C+39464m749H
wcY3LR+i5904l++KKDwILLvNPn/wwVe5T/ex+Fj7wduP9KQjBfz+5P4mBeXBtvI4cv/84TmXAL/U
+SIeE36P0614gzz+5llQ5g0jbxN7EOR2vK82pz9OGkgdB/PbZK5aXZUf/fevX1xG+TdqlN5lFX2y
kJ0L7DxX017Q0i40q/XrUr4HrWeITLSlwmk4N4Ah1kftMMoStzhAasfeEGbJUqLPgovuMhe2FulO
fMFVnN6AM2VEmC4gRt6H1qE7ojajIDjM5J3uA4ZrK9+vpD0ubFR7rC/FjB4rBq+czF/RvRrz410L
rnc+Pxntxyy45UgwQzN3ztM7M82mEnawtxGBAdMSBNKRNqH22HHXkOaAtOxEMrDmw1F/Gwf9REeW
U80WeoqORNpsjapYrm2+/+j3Q1arjf9UG/rH//xojgxxDT36CbeuVdwnLpBKSWzMrXe6FbPeb1pn
cjWC6eYT0FrE5lbYOLOYsZbeWuClXW/UDy0aoodhMgPNhacNsozxKUdbmWKfjUZJ4GHtjSdpa7NT
lqOcwPUgXfWx0bhUdeT7gQYca/22tOK/7jO3e1lzFsJPMFxeVfyUPLYT083jnD7++CbCcQsxe/nV
j106+AtzuyJY4b0d/7ROFL4WkIwzFtnSyE0phajJYCvzfury04UlAgrNti1tSK68EmAmMTrrTj2R
6fMMACH+cVljs503k8JdIiyo9a67GUIx5ot8N5z/SbVznvHxi8SGGwlCz6VyX8lrelS/4/TiN1KG
nonGV7VCXq048ahWSM2qE1uTz0lyjHCzLZ/SNI50eGFo7QYb0Cq4cIaxxTic7NZsh8/WLl8cBlJq
0hnLoHs4pgR7KqllOiZ9bSOGPOLzebt0zaZRbPUl5e8rFfIL4Osj/uEv5ZLekq52hJsHLbxeBimB
y+31gZjjJZPA5s5cFeO9YXC79tRHV1KJW5yVLbGELmxx6yYWLwPiGmT3RFYK0IgxAGTQK0O7N+TX
g23SpXvKyCfT7zf6rvFg/vVH+zUcrnq61mP/05OY3VdC7R71UPHvwePWuYsaAMignhRGCCTJAeV7
QtDpYb42clRH2SDghonxvnLAmXSpdEcDWQnGSTzh8CEmC31gw4cMjniS1IHkUFZMdJqghjreQasG
E7Ibn4Jg33PNHg9tFWLzhtr6eCYQL2S3fJCtRvH9pnWiViPG1DMVeOM6ebnGZjOSm2We3DYSOhkg
Zk4vc79MFomi59F8MFrtIaV9MG0ZauvWwudLk0lwgpKm6kg+GFwYResR6oTwtoHtcDV0n5iAH0Ag
1eWNv/TksEs+Xl/uX7D8anku89jSM7tlJNHu2FNa1TJvWc+wtOCXIKYfd3Hk7uMXLbge8HRG7qKQ
k6xxKXmZbCGanwVUTow9VVP9lChIQ1m3fQtKEC0ISFWA+QW9zCYTy9j0WKk7jF1/uUoOAiACxVzA
4nJJZl8Cev5FGa/XQ/IX1/N5ret/SMLtcbHQA91688jce34eebZ+mVi/zNanU+QeX6Gm2nozwmcj
Fjvn+NeYrvdpod+XCnFLupqeNw/qpkQwMo1v4Xxe9vd83EvEsGfCIRtuj/qHTtBLKjK73JpDVF3p
ddtaj4enPD3UV70D589H6XTh0LClCyAoqsyY3K+5/23v2JbayLF55itUpmoKMBhfcdjZmS3HNpeA
gWCcwGztlNXdwhZ0tzpSt7FTNfsv+YB92MrbvPrH9hy12tjG4ZKCbGW3TyXY7paOpHPTOUdqtSX3
QvvZTjcc8K9SrRKfK/JUsiFGIBZ+bMQoHrGyUqHbw4MrK4z6F1tveKVdyu4NrNPmqScian2wRh07
OD/v1ApRdveocyBOj/m2NTp++7qV9/esvYu964v9Om+5H4fXvcLB9YXnFSsvkOBiyoq4G6dR8ziw
2SPo5/PAM3dvt9FCaF983B55wxw98eH3p2c8p14B8esv2OozJAewJ1ex5PzNGK5fFpiNh/fu3tlI
tuDdzvdbDrOt+b7RTi8msJg7a7MrDL1+6MPwE9bdPV5E0QX18OIGA5/dcWKVmL0bjtxoQaWoR+UC
ZOAXJxn3in7/zzfE7LO0ePIBIYY4T683S78n1zfE/aZ60/R/OoKERU+vOeHi009vYXNHCdxf8+H5
T5vZwI3ABmwo4ILLLvk9b1j+Fnd1cROJib9zQx/I+gh3tbBT67tn9cOtg7eNoN2JHPm+k+2pgAaD
djb0Duq9an5wc0RrHYjGz/1Sc7O+lT3yb97tf2L5LWvUf3M6qL7v9X6rvj7I97NvN0+VI58/X3s3
K/vks+wKX3m64YEncacnjMr2rElKZobf4xk2Wfozi4C3bwB6ZMt3rcmdZ2xeRlDTVOD/SCrw9rVf
i9dLv+WIbIMT2Ga+6Vc6PsKdpOXO7jv64WSvsu0dn3cu/Npukd349rt2mZd3yqWzQemtqLWyqvi+
UfPa20fq4PVu0GgdyvreybXaOav2SwdbZ8eic+QXA6t6Ks6H5SeYltvDsZfw/x9Lr1L4v4FccopP
Lt6oAU77s7eRB9gql/UnwPxnvlAsvCpUitVivpAvFiuv8oVSoVp9RfLP3pMFEKmQSkJeSSHC+8o9
dP8HBTbEjT7EYZc0ckNtDuNpTyW2cWo7C1wy5pRGoQgkTIpDJpOr8OePn1Pj8WMB6D+1r2kPo3Xh
v0wbD+h/oVQuzel/sVAtp/r/PQB1PONTT3sCxXz59UYA3rWrfYdMIPkgzlMmvsP8G7RiNx8cjHiZ
J7kDeMgJ4iEDKEU2iL5y6QoJl2CiIad4NM46ORsFrK1rkhE5M4aG1NvtGG2SnjbHQOhrcUO3XqVx
buIYw/h6k7xXqGyyseGLpsdD8tNPBAuR+K4pCkZswNlNgoEkv81t7IFe/pvHllkyruXiYCwz95JY
zMBNvxL27slF09fNAVPTpxolbQ0WhmBJOmUea5JGnrk/jz0pYjJlJuq5RVWeisMz04Y/RpLHmG4y
rjtpxe0JKWe3Rf6ud0JXpwk9WY7M/HN68XE2fJw8oJD5ajIhPudap+dSd/YByG3W92pHu83D492c
57xMGw/Y/1IpP/H/ijgX5AuFSmErtf/fA5ZJvY9bVFzRW1paXibaqOO3ZXIUsYFY2iBra2eg9JKD
6WY+CcafQeEoWHEvcMHEr62Rle5yaEp0V7V5t6mUkWIu+JWkUCIBVQKcRwh+JVhy2+bjL/462SYe
9/lGSC0XH6ElHyNGMCYd/5v6xKUEj/+A2afHKaLRFz5G0PQ6/PQE0fszKC664n2XKBcMrsSiMBv1
qQ3fR6QXjf+lq0OvoHGI/XNk37fdaASmnvpxD/FBX3YFPRgRjypbhNCETwesR3VP9YguXZgHqNoE
3C7/RBG3JUK8i89vkwFmCCQBEl1FrCcI2CMSMIkdgo5DkZA7NAfErIUUW4JWQ2a71BF/Id1Ol2yS
bj2ULsmS37oxxqlBdFvmGo5S+NwRiKnBVOBy1gOqoVH2xp9DbgtCgV+7PNyLLHICbp3S/MmZFeIb
Ia9hFr7BcQSuGOVGHrJsRCQgo64j9Fi7jrDVZhcbMZNzF+gcUT3wnOqb3qAEcJfKdRJ3FB9k4ziR
q8jimhaSBbqrp81ao9XUuC3q+8xQT/hMYV1gMBLJCBbyUhMxF4thTQLXgVhhJCngarqESrvPB4KM
//RxxN1aEORCNewSxeAf9G38BSXVG38BtwEFzx1/6XEbmgAUQI0euDub3VXotxDXap3gSimwBygO
N3G7viYJDg96CFKmcAxNsBNAn0nviCcGwAmgdwQUA2E/ZSDaTHZ/vmUTYIHvvYhKB+tC9xyukHYo
UyDC7BIfYdDoT6QY4Q9NpPfoiWRnHKKE2oBmZUSJjz3RjgCKEvSg3jgiPjc/un/F5QL2a5fgkoMF
PVnFNt6g44OUgSJKuGJCyJWY49AUG+b6oZYJ1EboMLUk6J6wqeshKbRg454WwCkNg+pCSgZKjeyE
VloCNWFGITMtOkR51XKSIXH/JQPtT3h/qyCHVGlHkSlN60vhw5ChuE09iwPhAB34GDzWTIamxqGa
Fx6HDmpxQxGJHI5NaNZ+0jyaSAveqoM5YMOwS1YoMpjY4O5YWEwAdmnYtzqlsJpfqKLZNihr3XOy
NTMOIJLlCiAXdA7rujAArduKfKi1G2QlJrUdjv+EEkg/cGf5Jcijg6NcNT025gAxemB4GYESYHCI
HpaEL0CMcGKHVTj+DLzhTIaJMYjNkhLIMCwbm1WjCAPukkRswGzQTzMqt9INRWT3wbX1WXfV4DPW
x/AqQJGEKtTnnjGLwAkKjItZsXkZqYQlOHTTexhgSEHrHKqMtLS5H/NSoLA0ONp7sU70xg4Gymga
QGFah+o9RAbK6II91mazq4WxDYQA6wY26r89gf7gkMMtbEnm74USAA/F//lyZT7+LxfS+P+7gI7/
47mFyWMdwU+FlUCaHtMRWbNdzN9GeTDdNSDa8tmOkHXQULXDmeuomUUGfPANN9pNqpJM47hlPnL7
6LyBhcqY/WKZ26Mem+0jMM1JU+qaB4fcqpsgfAp/XOMUV2eiJPNgRb6Dx50k0aoLzs6+fpYRAsQz
1RyG4GGaMU6h4oADXE2nFa8PLWqnwdAHMc1cCmlPsg0mITBT5yp+i0scb+OPZDQh2Mu5sr7o+EBQ
5xANm1p87wScBo/hevz8/R0YY9iXIur16/gO8n2/fcPjRUmz6BmnDjh6vXrt7e8ZJW3kg96kY5Q/
VHglidGnrv4jjaBTSCGFFFJIIYUUUkghhRRSSCGFFH5k+A8i5EwkAEgDAA==
