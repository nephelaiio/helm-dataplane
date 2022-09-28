FROM python:3.10-buster
MAINTAINER Ted Cook <teodoro.cook@gmail.com>

RUN mkdir /dataplane

COPY ./dataplane /dataplane
COPY ./pyproject.toml /dataplane

WORKDIR /dataplane

RUN pip3 install poetry
RUN poetry config virtualenvs.create false
RUN poetry install --only main

CMD python "cli.py"
