# Venue Guide — Supabase Backend

Backend для iOS-приложения **Venue Guide** (Event Companion App).  
Реализует [API-контракт v1](07-api-contract.md).  
База: [Supabase](https://supabase.com) — PostgreSQL + Auth + Edge Functions.

## Структура

```
supabase/
├── migrations/
│   ├── 00001_initial_schema.sql        # Таблицы, индексы, RLS
│   ├── 00002_seed_data.sql             # Тестовые данные (EN, сентябрь)
│   ├── 00003_views_and_functions.sql   # Views (session_details, speaker_details)
│   ├── 00004_fix_functions.sql         # Фикс функций
│   ├── 00005_russian_data.sql          # Данные на русском, даты июль 29–31
│   └── 00006_playback_downloads_devices.sql  # Playback, downloads, devices
├── functions/
│   └── api/index.ts                    # Edge Function — REST API v1
└── seed.sql                            # Локальный посев
```

## Деплой

```bash
supabase link --project-ref <ref>
supabase db push
supabase functions deploy api --no-verify-jwt
```

GitHub Actions деплоит автоматически при пуше в `main`.

## API v1

Base: `https://<project>.supabase.co/functions/v1/api/v1`

### Auth

| Метод | Путь | Описание |
|--------|------|-----------|
| `POST` | `/auth/token` | Получить токен (password grant) |
| `POST` | `/auth/token/refresh` | Обновить токен |

### Conference (публичные)

| Метод | Путь | Описание |
|--------|------|-----------|
| `GET` | `/conferences/current` | Текущая/ближайшая конференция |
| `GET` | `/conferences/{id}/home` | Дашборд Home |
| `GET` | `/conferences/{id}/schedule?date=&status=` | Расписание по дням |
| `GET` | `/conferences/{id}/venue-map` | Карта площадки |

### Sessions & Speakers

| Метод | Путь | Описание |
|--------|------|-----------|
| `GET` | `/sessions/{id}` | Детали сессии + user_state |
| `GET` | `/speakers/{id}` | Профиль спикера + сессии |

### User actions (JWT)

| Метод | Путь | Описание |
|--------|------|-----------|
| `GET` | `/me` | Профиль, статистика, настройки |
| `GET` | `/me/ticket` | Билет + QR payload |
| `GET` | `/me/library?section=` | Библиотека (recent/favorites/downloads) |
| `GET` | `/me/notifications?unread_only=` | Уведомления |
| `PUT` | `/me/saved-sessions/{id}` | Сохранить в расписание |
| `DELETE` | `/me/saved-sessions/{id}` | Убрать из расписания |
| `PUT` | `/sessions/{id}/like` | Лайкнуть `{"liked": true/false}` |
| `PUT` | `/me/followed-speakers/{id}` | Подписаться |
| `DELETE` | `/me/followed-speakers/{id}` | Отписаться |
| `GET` | `/sessions/{id}/playback` | URL для плеера + resume |
| `PUT` | `/me/playback/{id}` | Сохранить прогресс |
| `POST` | `/sessions/{id}/downloads` | Создать загрузку |
| `GET` | `/me/downloads/{id}` | Статус загрузки |
| `DELETE` | `/me/downloads/{id}` | Отменить/удалить |
| `POST` | `/me/devices` | Зарегистрировать APNs |
| `GET` | `/me/devices` | Список устройств |
| `DELETE` | `/me/devices/{id}` | Отписать устройство |

### Формат ошибок

```json
{
  "error": {
    "code": "SESSION_NOT_FOUND",
    "message": "Сессия не найдена",
    "request_id": "req_01J...",
    "details": {}
  }
}
```

Коды: `INVALID_REQUEST`, `TOKEN_EXPIRED`, `FORBIDDEN`, `NOT_FOUND`, `SESSION_NOT_FOUND`, `CONFLICT`, `MEDIA_EXPIRED`, `RATE_LIMITED`, `INTERNAL_ERROR`.
