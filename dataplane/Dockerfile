FROM python:3-slim as python
ENV PYTHONUNBUFFERED=true
WORKDIR /app

FROM python as poetry
ENV POETRY_HOME=/opt/poetry
ENV POETRY_VIRTUALENVS_IN_PROJECT=true
ENV PATH="$POETRY_HOME/bin:$PATH"
RUN python -c 'from urllib.request import urlopen; print(urlopen("https://install.python-poetry.org").read().decode())' | python -
COPY . ./
RUN poetry self add poetry-plugin-bundle
RUN poetry bundle venv /app/bundle --clear

FROM python as runtime
ENV PYTHONPATH="/app/bundle/python3.x/site-packages:${PYTHONPATH}"
COPY --from=poetry /app/bundle /app/bundle
WORKDIR /app
ENTRYPOINT ["/app/bundle/bin/dataplane"]
