# affine-railway

Wrapper image for [AFFiNE](https://github.com/toeverything/AFFiNE) (open source Notion and Miro alternative: docs, whiteboards and databases in one workspace) on Railway.

It runs the official `ghcr.io/toeverything/affine` image, pinned by digest. The stock image takes its Postgres and Redis settings from the environment, needs a one-shot predeploy step (signing key and database migrations) before the server, lets the first visitor become the administrator and allows public registration. This wrapper builds the settings from plain Railway variables, binds to the injected `PORT`, runs the predeploy step, creates the administrator from `AFFINE_ADMIN_EMAIL` and `AFFINE_ADMIN_PASSWORD`, and closes public sign-up.

Needs Postgres 16 with pgvector and Redis alongside it and a volume at `/root/.affine`; the Railway template wires all three. Licence of this wrapper: MIT. AFFiNE itself is MIT (core) with its own terms for the enterprise directory.
