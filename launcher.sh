#!/bin/bash

# launch front
cd /app/front
yarn start &

# launch back
cd /app/back
python manage.py runserver --noreload 0:8000 &

# await of any
wait -n

# exit with first status acquired
exit $?