#!/bin/sh

if [ "$DEBUG" = 1 ]
then
    echo "Aguardando por postgres..."

    while ! nc -z $DB_HOST $DB_PORT; do
      sleep 0.1
    done

    echo "PostgreSQL preparado"
fi

python manage.py runserver 0.0.0.0:8000

exec "$@"