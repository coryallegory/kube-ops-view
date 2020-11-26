FROM node:14.0-slim AS nodebase

COPY app /app
COPY kube_ops_view /kube_ops_view

WORKDIR /app

RUN npm install
RUN npm run build

FROM python:3.8-slim AS pybase

WORKDIR /

RUN apt-get update && \
    apt-get install --yes --no-install-recommends curl gcc libc-dev libffi-dev make && \
    rm -rf /var/lib/apt/lists/*

RUN curl -sSL https://raw.githubusercontent.com/python-poetry/poetry/master/get-poetry.py | python

COPY poetry.lock /
COPY pyproject.toml /

RUN $HOME/.poetry/bin/poetry config virtualenvs.create false && \
    $HOME/.poetry/bin/poetry install --no-interaction --no-dev --no-ansi

FROM python:3.8-slim

WORKDIR /

# copy pre-built python packages to this image
COPY --from=pybase /usr/local/lib/python3.8/site-packages /usr/local/lib/python3.8/site-packages

# now copy the actual code we will execute (poetry install above was just for dependencies)
COPY  --from=nodebase /kube_ops_view /kube_ops_view

ARG VERSION=dev

RUN sed -i "s/__version__ = .*/__version__ = '${VERSION}'/" /kube_ops_view/__init__.py

ENTRYPOINT ["python3", "-m", "kube_ops_view"]
