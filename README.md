# Веб-приложение «Трекер менструального цикла»

**CycleTracker** — учебный веб-проект (MVP v1): простое приложение для отслеживания
менструального цикла с календарём, прогнозом, статьями, подсказками и системой уведомлений.

Реализовано по техническому заданию (`teh_z.docx`).

## Технологический стек

- **Frontend:** React 18 + Vite, TypeScript, React Router, CSS-переменные (две темы)
- **Backend:** Node.js + Express, TypeScript
- **База данных:** SQLite (встроенный модуль Node `node:sqlite`)
- **Аутентификация:** JWT (access — 15 мин + refresh — 7 дней в httpOnly cookie), bcrypt
- **Email:** Nodemailer (SMTP; без настроенного SMTP письма логируются в консоль)
- **Файлы:** локальная папка `backend/uploads`

## Быстрый старт

```bash
npm install && npm run dev
```

Это установит зависимости frontend/backend и запустит оба сервера:

- Frontend (Vite): http://localhost:5173
- Backend (API): http://localhost:3000/api

> Требуется Node.js 22.5 и выше (используется встроенный модуль `node:sqlite`).

## Конфигурация backend

Скопируйте `backend/.env.example` в `backend/.env` при необходимости.

| Переменная | По умолчанию | Описание |
|---|---|---|
| `PORT` | `3000` | Порт API |
| `JWT_SECRET` | `dev-secret-change-me` | Секрет для подписи JWT |
| `ADMIN_PASSWORD` | `admin123` | Пароль входа в админку (`/admin`) |
| `CORS_ORIGINS` | dev-адреса Vite | Разрешённые origin для CORS через запятую |
| `SMTP_HOST` / `SMTP_PORT` / `SMTP_USER` / `SMTP_PASS` | — | Настройки SMTP для email-напоминаний |
| `SMTP_FROM` | `CycleTracker <no-reply@example.com>` | Отправитель писем |

> `NODE_ENV=production` выставляется скриптом `npm start` автоматически (переменная
> `NODE_ENV` из `.env` не используется).

Без конфигурации SMTP письма никуда не отправляются, а «цепочка отправки»
(тема/текст/получатель) выводится в консоль backend — этого достаточно для
проверки критерия приёмки по email-напоминанию локально.

## Админка

- Адрес: `/admin`
- Пароль: значение `ADMIN_PASSWORD` из `backend/.env` (по умолчанию `admin123`)

В админке доступны CRUD статей (включая загрузку обложки) и CRUD подсказок.

## Структура проекта

```
cycle-tracker/
├── frontend/                 # React + Vite + TS
│   ├── src/
│   │   ├── components/       # Header, Calendar, ThemeToggle, ...
│   │   ├── pages/            # Экраны (Today, Calendar, Articles, ...)
│   │   ├── api/              # HTTP-клиент и методы API
│   │   ├── context/          # ThemeContext, AuthContext
│   │   ├── styles/           # global.css (CSS-переменные тем)
│   │   └── main.tsx
│   └── vite.config.ts        # proxy /api и /uploads на backend
├── backend/
│   ├── src/
│   │   ├── routes/           # API-маршруты
│   │   ├── controllers/      # Обработчики
│   │   ├── services/         # cycle, email, notifications, seed
│   │   ├── middleware/       # auth, adminAuth, errorHandler, logger
│   │   └── index.ts
│   ├── uploads/              # Загруженные обложки статей
│   └── .env.example
└── README.md
```

## Деплой

Backend раздаёт собранный frontend (`frontend/dist`) на том же порту, поэтому всё
приложение живёт на одном origin: `npm run build && npm start`.

1. **Соберите приложение:**
   ```bash
   npm ci
   npm run build        # frontend/dist
   npm start            # НODE_ENV=production, слушает :$PORT, раздаёт API + frontend
   ```

2. **Перед запуском в проде обязательно:**
   - поставьте свой `JWT_SECRET` в `backend/.env`;
   - смените `ADMIN_PASSWORD`;
   - укажите реальный `SMTP_*`, иначе напоминания не будут отправляться (только лог в консоль);
   - задайте `CORS_ORIGINS`, если API и frontend на разных origin (в single-port режиме не требуется).

3. **Нужен HTTPS:** `npm start` ставит `NODE_ENV=production`, и refresh-токен пишется
   в `secure` cookie — за прокси (nginx/Caddy) это корректно работает при включённом
   `trust proxy`. На HTTP (`secure` cookie) refresh не сохранится.

4. **Персистентность и бэкапы:** данные — SQLite-файл в `backend/data/`, обложки —
   `uploads/`. Оба пути должны быть на постоянном диске и попадать в бэкапы.

5. **Процесс:** запускайте как сервис (systemd, PM2, Docker) с рестартом после падения.
   Требуется Node.js ≥ 22.5.

> Для защиты от перебора паролей в проде рекомендуется rate-limiting на
> `/api/auth/login` (в текущей версии не реализован — учебный MVP).

## Основные эндпоинты

- `POST /api/auth/register | login | refresh | logout`
- `GET/PATCH/DELETE /api/me`, `POST /api/me/change-password`
- `GET /api/cycle/summary`, `GET/POST/DELETE /api/cycle/entries`
- `GET /api/articles`, `GET /api/articles/:slug`
- `GET /api/notifications`, `PATCH /api/notifications/:id/read`
- `POST /api/admin/login`, `CRUD /api/admin/articles`, `CRUD /api/admin/tips`

Полный перечень — в техническом задании (`teh_z.docx`).

## Формат ошибок

Все ошибки возвращаются в едином формате:

```json
{ "error": "описание", "code": "машинный_код" }
```