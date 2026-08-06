# Гайд: от Figma-макета до работающего API на Supabase

Полная инструкция — от регистрации до демонстрации. Используем реальный кейс: приложение **Venue Guide** (iOS-компаньон для конференций).

---

## 0. Что понадобится

- Аккаунт на [GitHub](https://github.com)
- Аккаунт на [Supabase](https://supabase.com)
- Figma-макет приложения (файл `.fig` или `.make`)
- Терминал с `git`, `curl`, `python3`

---

## 1. Подготовка

### 1.1. GitHub

1. Регистрируемся на [github.com](https://github.com)
2. Создаём новый репозиторий: **+** → **New repository**
3. Название: `app-example`, приватность — на ваш выбор
4. Клонируем репозиторий локально:
   ```bash
   git clone https://github.com/<ваш-username>/app-example.git
   cd app-example
   ```

### 1.2. Supabase

1. Регистрируемся на [supabase.com](https://supabase.com)
2. Создаём новый проект: **New project**
3. Заполняем:
   - **Name:** `venue-guide`
   - **Database Password:** придумываем надёжный пароль (сохраняем!)
   - **Region:** ближайший к вам
4. Ждём создания (1–2 минуты)

### 1.3. Получаем ключи доступа

В Supabase Dashboard заходим в проект, затем:

1. **Settings → API** — копируем:
   - `Project URL` (вида `https://xxxxxxxxxxxx.supabase.co`)
   - `anon public` ключ (начинается с `sb_publishable_` или `eyJ...`)

2. **Settings → General** — копируем:
   - `Reference ID` (вида `abcdefghijklm`) — это `SUPABASE_PROJECT_ID`

3. [supabase.com/dashboard/account/tokens](https://supabase.com/dashboard/account/tokens) — генерируем:
   - **Personal Access Token** (начинается с `sbp_`) — это `SUPABASE_ACCESS_TOKEN`

### 1.4. Настройка GitHub Actions (деплой)

1. В репозитории на GitHub: **Settings → Environments → New environment**
2. Название: `prod`
3. В созданном `prod` → **Environment secrets → Add secret** — добавляем три секрета:

   | Имя | Значение |
   |-----|----------|
   | `SUPABASE_ACCESS_TOKEN` | Токен `sbp_...` из п.1.3 |
   | `SUPABASE_PROJECT_ID` | Reference ID из п.1.3 |
   | `SUPABASE_DB_PASSWORD` | Пароль БД из п.1.2 |

4. **Authentication → Settings → Email** — отключаем **Enable email confirmations** (для тестового пользователя)

5. **Authentication → Providers → Email** — убеждаемся что **включён**

---

## 2. Анализ Figma-макета

### 2.1. Извлечение документации из `.make` / `.fig`

```bash
# Распаковываем .make (это zip-архив)
unzip Venue.make -d Venue_extracted
```

Извлекаем содержимое `ai_chat.json` — там полная история дизайна: описание продукта, экраны, данные.

```bash
python3 << 'EOF'
import json
with open('Venue_extracted/ai_chat.json') as f:
    d = json.load(f)
thread = d['threads'][0]
for msg in thread['messages']:
    for part in msg.get('parts', []):
        if 'tool-result' in part.get('partType', ''):
            cj = json.loads(part['contentJson'])
            result = json.loads(cj['resultJson'])
            content = result.get('content', '')
            if content and len(content) > 100:
                print(content.replace('\\n', '\n')[:5000])
EOF
```

### 2.2. Что ищем в макете

Для проектирования API из макета нужно извлечь:

- **Экраны** (Home, Schedule, Map, Library, Profile, Session Detail, Speaker Profile, Player, Notifications)
- **Модели данных** (Session, Speaker, Room, User, Notification, Ticket)
- **Состояния экранов** (live / upcoming / recorded, saved / not saved, liked / not liked)
- **Навигацию** (табы, модальные окна, переходы)
- **Бизнес-логику** (сохранение сессий, лайки, follow, плеер с PiP)

### 2.3. Формируем структуру БД

На основе моделей создаём таблицы:

```
events            — конференция
categories        — категории сессий (Keynote, Workshop, Talk)
sessions          — доклады (название, описание, время, статус, комната)
speakers          — спикеры
session_speakers  — связь many-to-many
rooms             — комнаты и сцены
venue_locations   — карта площадки (координаты)
recordings        — библиотека записей
user_profiles     — профили пользователей
user_saved_sessions   — личное расписание
user_liked_sessions   — лайки
user_followed_speakers — подписки на спикеров
notifications     — уведомления
playback_state    — прогресс просмотра
downloads         — офлайн-загрузки
devices           — APNs-устройства
```

---

## 3. Структура проекта

```
app-example/
├── supabase/
│   ├── migrations/
│   │   ├── 00001_initial_schema.sql        # Таблицы, индексы, RLS
│   │   ├── 00002_seed_data.sql             # Тестовые данные
│   │   ├── 00003_views_and_functions.sql   # Представления и функции
│   │   └── 00004_playback_downloads_devices.sql  # Доп. таблицы
│   └── functions/
│       └── api/
│           └── index.ts                    # Edge Function (Deno)
├── .github/
│   └── workflows/
│       └── deploy.yml                      # CI/CD
├── openapi.yaml                            # OpenAPI 3.0 спека
├── README.md
└── .gitignore
```

---

## 4. Создание бэкенда

### 4.1. Миграции — SQL

Создаём файлы миграций в `supabase/migrations/`. Каждый файл — нумерованный SQL-скрипт.

**`00001_initial_schema.sql`** — таблицы, индексы, RLS-политики:

```sql
CREATE TABLE events (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  name TEXT NOT NULL,
  slug TEXT UNIQUE NOT NULL,
  -- ...
);

-- Row Level Security: публичное чтение event-данных
ALTER TABLE events ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Public read events" ON events FOR SELECT USING (true);

-- Для user-данных — доступ только владельцу
ALTER TABLE user_saved_sessions ENABLE ROW LEVEL SECURITY;
CREATE POLICY "User manage own schedule" ON user_saved_sessions
  USING (auth.uid() = user_id);
```

**`00002_seed_data.sql`** — тестовые данные. Заполняем конференцию, спикеров, сессии.

Важно: UUID должны быть hex-символами (`0-9`, `a-f`). Не используйте буквы `g-z` в UUID.

### 4.2. Edge Function (API) — TypeScript/Deno

Файл `supabase/functions/api/index.ts`:

```typescript
import { serve } from "https://deno.land/std@0.177.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

serve(async (req: Request) => {
  const url = new URL(req.url);
  // Supabase стрипит /functions/v1, оставляет /api/<route>
  let path = url.pathname.replace(/^\/api\/?/, "/").replace(/^\/v1\/?/, "/");

  // Публичный эндпоинт
  if (req.method === "GET" && path === "/conferences/current") {
    const { data, error } = await supabaseAdmin
      .from("events").select("*").eq("is_active", true).single();
    return json(data, corsHeaders);
  }

  // Авторизованный эндпоинт
  const { data: { user } } = await supabase.auth.getUser();
  if (req.method === "GET" && path === "/me") {
    if (!user) return json({ error: "Unauthorized" }, 401);
    // ...
  }
});
```

### 4.3. GitHub Actions — деплой

`.github/workflows/deploy.yml`:

```yaml
name: Deploy to Supabase
on:
  push:
    branches: [main]
    paths: ["supabase/**", ".github/workflows/deploy.yml"]
jobs:
  deploy:
    runs-on: ubuntu-latest
    environment: prod
    env:
      SUPABASE_ACCESS_TOKEN: ${{ secrets.SUPABASE_ACCESS_TOKEN }}
      SUPABASE_DB_PASSWORD:  ${{ secrets.SUPABASE_DB_PASSWORD }}
      SUPABASE_PROJECT_ID:   ${{ secrets.SUPABASE_PROJECT_ID }}
    steps:
      - uses: actions/checkout@v4
      - uses: supabase/setup-cli@v1
        with: { version: latest }
      - run: supabase link --project-ref "$SUPABASE_PROJECT_ID"
      - run: supabase db push
      - run: supabase functions deploy api --project-ref "$SUPABASE_PROJECT_ID" --no-verify-jwt
```

---

## 5. Деплой и проверка

### 5.1. Пушим — деплой автоматический

```bash
git add -A
git commit -m "feat: initial backend"
git push origin main
```

GitHub Actions запустится автоматически. Смотрим статус во вкладке **Actions**.

### 5.2. Проверяем API

Базовый URL: `https://<project-ref>.supabase.co/functions/v1/api`

```bash
# Публичные эндпоинты
curl https://<project-ref>.supabase.co/functions/v1/api/conferences/current
curl https://<project-ref>.supabase.co/functions/v1/api/conferences/<event-id>/home
curl https://<project-ref>.supabase.co/functions/v1/api/conferences/<event-id>/schedule
curl https://<project-ref>.supabase.co/functions/v1/api/sessions/<session-id>
curl https://<project-ref>.supabase.co/functions/v1/api/speakers/<speaker-id>
curl https://<project-ref>.supabase.co/functions/v1/api/conferences/<event-id>/venue-map
```

### 5.3. Создаём тестового пользователя

```bash
# Регистрация (anon key из Supabase → Settings → API)
curl -X POST "https://<project-ref>.supabase.co/auth/v1/signup" \
  -H "apikey: <anon-key>" \
  -H "Content-Type: application/json" \
  -d '{"email":"demo@venueguide.com","password":"demopass123"}'

# Логин через API
curl -X POST https://<project-ref>.supabase.co/functions/v1/api/auth/token \
  -H "Content-Type: application/json" \
  -d '{"grant_type":"password","email":"demo@venueguide.com","password":"demopass123"}'

# Профиль (с токеном из ответа)
curl https://<project-ref>.supabase.co/functions/v1/api/me \
  -H "Authorization: Bearer <access_token>"
```

---

## 6. Документирование API

### 6.1. OpenAPI 3.0 спека

Файл `openapi.yaml` в корне репозитория. Описывает все эндпоинты, модели, коды ошибок.

Просмотр спеки:
- [Swagger Editor](https://editor.swagger.io/?url=https://raw.githubusercontent.com/<user>/<repo>/main/openapi.yaml)
- [Scalar](https://docs.scalar.com) — более современный рендерер

### 6.2. README

Должен содержать:
- Структуру проекта
- Таблицу эндпоинтов (публичные и авторизованные)
- Инструкцию по локальному запуску
- Формат ошибок
- Демо-учётные данные

---

## 7. Типичные ошибки и их решение

| Ошибка | Причина | Решение |
|--------|---------|---------|
| `SUPABASE_ACCESS_TOKEN: ` (пусто) | Секреты созданы как Variables, а не Secrets | Settings → Secrets and variables → Actions → **Secrets** (не Variables!) |
| `Access token not provided` | Секреты созданы в Environment, а не Repository | Либо перенести в Repository secrets, либо добавить `environment: prod` в workflow |
| `Invalid access token format. Must be like sbp_...` | Использован Project API key вместо Personal Access Token | Сгенерировать токен на [supabase.com/dashboard/account/tokens](https://supabase.com/dashboard/account/tokens) |
| `invalid input syntax for type uuid` | UUID содержит не-hex буквы (`g-z`) | Использовать только `0-9`, `a-f` |
| `column must appear in GROUP BY` | `json_agg(*.*)` с `ORDER BY` | Заменить на подзапросы с `row_to_json()` |
| `ProjectConfigParseError` | config.toml содержит устаревшие секции | Удалить `[inbucket]` (заменить на `[local_smtp]`) или удалить config.toml для production |
| `UNAUTHORIZED_NO_AUTH_HEADER` | JWT-верификация включена на функции | Добавить `--no-verify-jwt` при деплое |
| `email_not_confirmed` | Пользователь создан до отключения подтверждения | Подтвердить вручную в Auth → Users или создать нового |
| `Email logins are disabled` | Отключён email-провайдер | Auth → Providers → Email → включить |

---

## 8. Чек-лист

- [ ] GitHub: репозиторий создан
- [ ] Supabase: проект создан, ключи скопированы
- [ ] GitHub Environments: `prod` с тремя секретами
- [ ] Supabase Auth: email-провайдер включён, подтверждение отключено
- [ ] Миграции: все SQL-файлы созданы и протестированы
- [ ] Edge Function: API реализована, `--no-verify-jwt` установлен
- [ ] GitHub Actions: workflow проходит без ошибок
- [ ] Публичные эндпоинты: все возвращают 200
- [ ] Авторизованные эндпоинты: работают с JWT-токеном
- [ ] OpenAPI-спека: валидна и открывается в Swagger Editor
- [ ] README: актуален
- [ ] Демо-пользователь: создан, логин работает
