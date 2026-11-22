
# Guestbook — Flask + PostgreSQL + Nginx Infrastructure

Контейнеризований вебзастосунок **Guestbook** (Flask + Gunicorn + PostgreSQL + Nginx) з реалізованим шаблоном **PRG (Post/Redirect/Get)** проти повторної відправки форм, автоматичним резервним копіюванням бази даних і моніторингом стану системи через `cron` та `journalctl`.

## Архітектура та структура проєкту

Дані проєкту розміщуються на окремому LVM-розділі `/mnt/app_data/guestbook`.

```text
/mnt/app_data/guestbook/
├── app/
│   ├── app.py              # Flask-застосунок (логіка маршрутів та PRG-патерн)
│   ├── Dockerfile          # Збірка образу вебзастосунку
│   └── requirements.txt    # Python-залежності
├── nginx/
│   └── default.conf        # Конфігурація reverse proxy для Nginx
├── backups/                # Локальна директорія архівів (ігнорується Git)
├── docker-compose.yml      # Опис сервісів db, web, nginx, мереж і volumes
├── .env.example            # Шаблон змінних оточення (без реальних секретів)
├── .gitignore              # Виключення секретів, бекапів, логів і кешу
├── backup.sh               # Скрипт дампу БД, архівації та ротації
└── health-check.sh         # Перевірка заповнення LVM-розділу та статусу контейнерів


## Запуск

1. Створіть `.env` на основі `.env.example` і заповніть змінні:
```bash
cp .env.example .env

2. Запустіть сервіси:
```bash
docker compose up -d --build


## Автоматизація (Cron)

- Переконайтеся, що `backup.sh` і `health-check.sh` мають права на виконання (`chmod +x`).
- Додайте завдання у `crontab -e` та перевіряйте логи через `journalctl -t logger -n 20 --no-pager`.
