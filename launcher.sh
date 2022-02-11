#!/bin/bash

# launch front
cd /app/front
find .nuxt/ \
  -type f \
  -name '*.js' \
  -exec sed -i "s+%%TARGET_HOSTNAME%%+${TARGET_HOSTNAME}+g" {} \;
yarn start &

# launch back
cd /app/back
gunicorn --bind=0.0.0.0:8000 --threads=10 --workers=1 streamfeast_api.wsgi &

# await of any
wait -n

# exit with first status acquired
exit $?
