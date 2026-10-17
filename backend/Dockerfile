# Minimal API image. Phase 7 (hardening) extends this with a multi-stage production build.
FROM node:22-bookworm-slim

# poppler-utils: `pdftoppm` renders PDF page 1 for previews. fonts-dejavu-core: sharp/librsvg needs a font to draw watermark text.
RUN apt-get update \
  && apt-get install -y --no-install-recommends poppler-utils fonts-dejavu-core openssl ca-certificates \
  && rm -rf /var/lib/apt/lists/*

WORKDIR /app
COPY package*.json ./
RUN npm ci
COPY . .
RUN npx prisma generate && npm run build

ENV NODE_ENV=production
EXPOSE 3000
CMD ["node", "dist/main"]
