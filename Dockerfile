# AFFiNE wrapper for Railway. The official image expects its Postgres and Redis settings from the environment, a one-shot
# self-host-predeploy.js (private key plus database migrations) before the server, and the first visitor to /admin/setup becomes the
# administrator while anyone can register. This image builds those settings from the Railway variables, binds to Railway's injected
# PORT, runs the predeploy step, creates the administrator from AFFINE_ADMIN_EMAIL / AFFINE_ADMIN_PASSWORD and closes public sign-up.
# upstream: toeverything/AFFiNE
FROM ghcr.io/toeverything/affine:0.27.4@sha256:b649f5ce2384ffdf13c23bccf81d759e15973d59d0b0058af65d895a84373099

COPY --chmod=0755 boot.sh /railway-boot.sh

EXPOSE 8080
ENTRYPOINT ["/railway-boot.sh"]
CMD ["node", "./dist/main.js"]
