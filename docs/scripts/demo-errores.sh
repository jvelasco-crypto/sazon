#!/bin/zsh
# Demostración de los errores del backend de reseñas (cada uno con su código y mensaje).
# uso: docs/scripts/demo-errores.sh <correo> <archivo-con-la-contraseña>
# La contraseña se lee de un archivo para no escribirla en la terminal ni en el historial.
B=${BACKEND_URL:-http://localhost:8000}; CORREO=$1; CLAVE="$(cat $2)"
mostrar() { printf '%-55s → ' "$1"; shift; curl -s -w ' [%{http_code}]\n' "$@" | sed -E 's/"access_token":"[^"]+"/"access_token":"***"/'; }
T=$(curl -s -X POST $B/usuarios/token --data-urlencode "username=$CORREO" --data-urlencode "password=$CLAVE" | python3 -c 'import sys,json;print(json.load(sys.stdin)["access_token"])')
H="Authorization: Bearer $T"
mostrar "Sin token (funcionalidad protegida)" "$B/resenas/?receta_id=53050"
mostrar "Token inválido" -H "Authorization: Bearer token-falso" "$B/resenas/mias"
mostrar "Reseña duplicada (regla de negocio)" -X POST -H "$H" -H 'Content-Type: application/json' -d '{"receta_id":"53050","receta_nombre":"Ayam Percik","calificacion":4,"comentario":"otra"}' "$B/resenas/"
mostrar "Calificación fuera de rango (validación)" -X POST -H "$H" -H 'Content-Type: application/json' -d '{"receta_id":"1","receta_nombre":"X","calificacion":9,"comentario":"x"}' "$B/resenas/"
R=$(curl -s -H "$H" "$B/resenas/?receta_id=53050" | python3 -c 'import sys,json;print(next(r["id"] for r in json.load(sys.stdin) if not r["es_mia"]))')
mostrar "Borrar la reseña de OTRA persona" -X DELETE -H "$H" "$B/resenas/$R"
mostrar "Reseña que no existe" -X PATCH -H "$H" -H 'Content-Type: application/json' -d '{"calificacion":2}' "$B/resenas/99999"
