#!/bin/sh
# AFFiNE on Railway: build the server's settings from the Railway variables, run upstream's predeploy step (private key and database
# migrations), start the stock server, then create the administrator through the first-run endpoint and keep sign-up closed.
set -eu
cd /app

need() { eval "v=\${$1:-}"; [ -n "$v" ] || { echo "[railway-boot] $1 is required" >&2; exit 1; }; }
for n in DB_HOST DB_USER DB_PASS DB_NAME REDIS_HOST REDIS_PASS AFFINE_ADMIN_EMAIL AFFINE_ADMIN_PASSWORD RAILWAY_PUBLIC_DOMAIN; do need "$n"; done

PORT="${PORT:-8080}"
export DATABASE_URL="postgresql://$DB_USER:$DB_PASS@$DB_HOST:5432/$DB_NAME"
export REDIS_SERVER_HOST="$REDIS_HOST" REDIS_SERVER_PORT=6379 REDIS_SERVER_PASSWORD="$REDIS_PASS"
export AFFINE_SERVER_PORT="$PORT" AFFINE_SERVER_HOST="$RAILWAY_PUBLIC_DOMAIN" AFFINE_SERVER_HTTPS=true \
       AFFINE_SERVER_EXTERNAL_URL="https://$RAILWAY_PUBLIC_DOMAIN"
unset DB_PASS REDIS_PASS

# one volume at /root/.affine holds the signing key (config/private.key) and uploaded blobs (storage/); it is mounted root-owned
CONF=/root/.affine/config
mkdir -p "$CONF" /root/.affine/storage
[ -w /root/.affine/storage ] || { echo "[railway-boot] /root/.affine is not writable (owner $(stat -c %u:%g /root/.affine))" >&2; exit 1; }
# anyone can register on a stock deploy; the administrator is created below and further accounts are added by that administrator
printf '{"auth":{"allowSignup":false,"allowSignupForOauth":false}}\n' > "$CONF/config.json"
echo "[railway-boot] /root/.affine owner=$(stat -c %u:%g /root/.affine), serving https://$RAILWAY_PUBLIC_DOMAIN on $PORT"

node ./scripts/self-host-predeploy.js

"$@" &
SERVER=$!
trap 'kill -TERM "$SERVER" 2>/dev/null' TERM INT

# first run: create the administrator, only while no user exists (the endpoint refuses once one does)
i=0
until [ "$(node -e "fetch('http://127.0.0.1:$PORT/info').then(r=>process.stdout.write(String(r.status))).catch(()=>process.stdout.write('0'))")" = 200 ]; do
  i=$((i+1)); kill -0 "$SERVER" 2>/dev/null || { echo "[railway-boot] server exited before it answered /info" >&2; wait "$SERVER"; exit $?; }
  [ "$i" -le 120 ] || { echo "[railway-boot] /info did not answer in 240 s" >&2; break; }
  sleep 2
done
node -e "
const u='http://127.0.0.1:$PORT/api/setup/create-admin-user';
fetch(u,{method:'POST',headers:{'content-type':'application/json'},body:JSON.stringify({email:process.env.AFFINE_ADMIN_EMAIL,password:process.env.AFFINE_ADMIN_PASSWORD,name:'Admin'})})
 .then(async r=>console.log('[railway-boot] create-admin-user '+r.status+' '+(await r.text()).slice(0,160)))
 .catch(e=>console.log('[railway-boot] create-admin-user failed: '+e.message))"

wait "$SERVER"
