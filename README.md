# ENV config

```
DEBUG=True
SECRET_KEY=************
DATABASE_URL=psql://log:pass@host:port/db
EMAIL_CONFIG=smtp+tls://user:pass@smtp.yandex.ru:587
TARGET_HOSTNAME=http://sf.voronov.at

PAYMENT_TEST_MODE=True
PAYMENT_KEY=************
PAYMENT_MERCHANT_ID=************
```

# Launcher
```
docker run -d \
    --mount type=bind,source=/home/streamfest/media,target=/app/back/media \
    --mount type=bind,source=/home/streamfest/logs,target=/app/back/logs \
    --network=host \
    --env-file=.env \
    sf:latest
```
