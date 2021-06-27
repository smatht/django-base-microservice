# =============
# BUILDER IMAGE
# =============
FROM python:3.8.3-alpine as builder

WORKDIR /usr/src/app
ENV PYTHONDONTWRITEBYTECODE 1
ENV PYTHONUNBUFFERED 1

RUN apk update \
   && apk add postgresql-dev gcc python3-dev musl-dev \
   && apk add libffi-dev openssl-dev \
   && rm -rf /var/cache/apk/*

COPY ./requirements.txt .
RUN pip install -U pip \
   && pip wheel --no-cache-dir -r requirements.txt

# ==================
# BASE IMAGE
# ==================

FROM python:3.8.3-alpine as base

RUN mkdir -p /home/app
RUN addgroup -S app && adduser -S app -G app

ENV HOME=/home/app
ENV SERVICE_HOME=/home/app/service
RUN mkdir $SERVICE_HOME
WORKDIR $SERVICE_HOME

RUN apk update && apk add libpq \
    && apk add --no-cache tzdata
COPY --from=builder /usr/src/app /wheels
RUN pip install -U pip \
    && pip install -r /wheels/requirements.txt -f /wheels \
    && rm -rf /wheels \
    && pip install debugpy -t /tmp

RUN apk add --no-cache tzdata
ENV TZ America/Buenos_Aires
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

COPY ./entrypoint.sh $HOME
RUN chown -R app:app $HOME

# ==================
# DEVELOPMENT IMAGE
# ==================

FROM base as dev
COPY ./source $SERVICE_HOME
ENTRYPOINT ["/home/app/entrypoint.sh"]
