#!/bin/bash

LVM_MOUNT="/mnt/app_data"
WARNING_THRESHOLD=85
# Вкажіть точні імена ваших контейнерів (можете перевірити їх через docker ps)
CONTAINERS=("devops_db" "devops_web" "devops_nginx")

# --- 1. ПЕРЕВІРКА ДИСКОВОГО ПРОСТОРУ ---
DISK_USAGE=$(df "$LVM_MOUNT" | awk 'NR==2 {print $5}' | tr -d '%')
echo "[INFO] Поточне заповнення LVM-розділу $LVM_MOUNT: ${DISK_USAGE}%"

if [ "$DISK_USAGE" -ge "$WARNING_THRESHOLD" ]; then
    MESSAGE="УВАГА: Дисковий простір на LVM-розділі $LVM_MOUNT заповнено на ${DISK_USAGE}%!"
    logger -p user.warning "$MESSAGE"
fi

# --- 2. ПЕРЕВІРКА СТАТУСУ DOCKER-КОНТЕЙНЕРІВ ---
for container in "${CONTAINERS[@]}"; do
    # Перевіряємо чи існує контейнер взагалі
    if docker ps -a --format '{{.Names}}' | grep -q "^${container}$"; then
        STATUS=$(docker inspect -f '{{.State.Running}}' "$container" 2>/dev/null)
        if [ "$STATUS" = "true" ]; then
            echo "[OK] Контейнер $container працює нормально."
        else
            ERR_MSG="КРИТИЧНА ПОМИЛКА: Контейнер $container зупинено!"
            echo "$ERR_MSG" >&2
            logger -p user.err "$ERR_MSG"
        fi
    else
        echo "[ПОПЕРЕДЖЕННЯ] Контейнер з ім'ям '$container' не знайдено в системі."
    fi
done

echo "Моніторинг стану завершено."
