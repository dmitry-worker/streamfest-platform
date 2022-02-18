FROM node:12-alpine as node-compiler

# Stage-1 work dir doesn't matter
WORKDIR /app

COPY front .

RUN yarn install \
    --prefer-offline \
    --frozen-lockfile \
    --non-interactive \
    --production=false

# Shitty Nuxt cannot read env on application start
# It must receive all the arguments when it builds
# We will swap it later
RUN \
    export TARGET_HOSTNAME='%%TARGET_HOSTNAME%%' && \
    yarn build

RUN rm -rf node_modules && \
    NODE_ENV=production yarn install \
    --prefer-offline \
    --pure-lockfile \
    --non-interactive \
    --production=true


#
# It makes no sense to go 2-stage build with python
# becaues f**cking Pillow requires /usr/lib wrapped .so files
# So you have to install *-dev packages onto your alpine 20M image.
# And it quickly becomes 700M afterwards
#
# We're going to construct the following package structure:
#
# app
#  |-front   <- nodejs
#  `-back    <- python django
#
FROM nikolaik/python-nodejs:python3.9-nodejs12-alpine


###################
# PART 1: node.js #
###################
WORKDIR /app/front
COPY --from=node-compiler /app .
EXPOSE 3000


##################
# PART 2: django #
##################
# But try to stick to "venv" anyway
# That will help us going multistage
# Make sure we use the virtualenv:
RUN python -m venv /opt/venv
ENV PATH="/opt/venv/bin:$PATH"
WORKDIR /app/back
# this will move everything to app dir
COPY back .
# We don't need postgres binaries because we (thank god!) use psycopg2-binary
# But we have to provide libjpeg and all the other trash for pillow to work
RUN apk update \
    && apk add --virtual build-deps gcc python3-dev musl-dev \
    # && apk add postgresql \
    # && apk add postgresql-dev \
    # && pip install psycopg2 \
    && apk add jpeg-dev zlib-dev libjpeg
#   # && pip install Pillow
#   # && apk del build-deps
RUN pip install -r requirements.txt
# Keeps Python from generating .pyc files in the container
# We probably need this as everything is compiled on compile-image
ENV PYTHONDONTWRITEBYTECODE=1
# Turns off buffering for easier container logging
ENV PYTHONUNBUFFERED=1
# No more debug
ENV DJANGO_DEBUG=False
EXPOSE 8000


##################
# PART 3: launch #
##################
# bash is required to run both processes simultaneously
RUN apk add --no-cache bash

# We will start both services using custom launcher script!
WORKDIR /app
COPY launcher.sh .

# Create a user (don't run as root)
RUN adduser -u 5678 --disabled-password --gecos "" appuser && chown -R appuser /app
USER appuser

CMD ["bash", "launcher.sh"]
