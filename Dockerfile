FROM node:22-alpine

WORKDIR /app

# Копируем package.json для кэширования зависимостей
COPY package.json ./
COPY backend/package.json ./backend/
COPY frontend/package.json ./frontend/

# Устанавливаем зависимости.
# backend ставим ПОЛНОСТЬЮ (devDeps нужны для tsc-сборки), frontend — полностью (нужно для vite).
# Корневой npm ci не нужен: у корня только dev-зависимость concurrently, она не нужна в проде.
RUN npm --prefix backend ci && \
    npm --prefix frontend ci

# Копируем весь проект
COPY . .

# Собираем frontend (в frontend/dist) и backend (в backend/dist)
RUN npm run build && npm --prefix backend run build

# Директории для данных. База: /app/backend/data, обложки: /app/uploads (см. index.ts)
RUN mkdir -p backend/data uploads

EXPOSE 3000

ENV NODE_ENV=production
ENV PORT=3000

# Секреты (JWT_SECRET, ADMIN_PASSWORD, SMTP_*) передавайте через `docker run -e`/compose.
CMD ["npm", "start"]