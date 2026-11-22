#!/bin/bash

# Налаштування змінних середовища
CONTAINER_NAME="devops_db"
DB_USER="appuser"
DB_NAME="appdb"
BACKUP_DIR="/mnt/app_data/guestbook/backups"

# Створюємо директорію для бекапів, якщо вона ще не існує (-p запобігає помилкам)
mkdir -p "$BACKUP_DIR"

# Генеруємо унікальну мітку часу для назви архіву (формат: YYYY-MM-DD_HH-MM-SS)
TIMESTAMP=$(date +"%Y-%m-%d_%H-%M-%S")
BACKUP_NAME="db_backup_$TIMESTAMP"
BACKUP_PATH="$BACKUP_DIR/$BACKUP_NAME"

echo "[$TIMESTAMP] Початок створення резервної копії бази даних..."

# Крок 1: Експортуємо дамп бази даних безпосередньо з працюючого Docker-контейнера
docker exec -t "$CONTAINER_NAME" pg_dump -U "$DB_USER" "$DB_NAME" > "$BACKUP_PATH.sql"

# Перевіряємо, чи успішно створився SQL-файл
if [ $? -eq 0 ]; then
    echo "Дамп успішно створено. Упаковуємо в архів..."
    
    # Крок 2: Архівовуємо SQL-файл за допомогою gzip для економії місця
    tar -czf "$BACKUP_PATH.tar.gz" -C "$BACKUP_DIR" "$BACKUP_NAME.sql"
    
    # Видаляємо проміжний неархівований файл, залишаючи лише .tar.gz
    rm "$BACKUP_PATH.sql"
    
    echo "Резервна копія успішно збережена: $BACKUP_PATH.tar.gz"
else
    echo "ПОМИЛКА: Не вдалося створити дамп бази даних!" >&2
    exit 1
fi

# Крок 3: Ротація бекапів — автоматичне видалення архівів, старших за 7 днів
echo "Очищення старих архівів (старших за 7 днів)..."
find "$BACKUP_DIR" -name "db_backup_*.tar.gz" -mtime +7 -exec rm {} \;

echo "Процес резервного копіювання завершено успішно."
