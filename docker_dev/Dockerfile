FROM elixir:1.14

RUN apt-get update && \
    apt-get install -y \
    postgresql-client \
    inotify-tools

RUN mkdir -p /app
VOLUME [ "/app/" ]
WORKDIR /app
COPY . /app/

RUN mix local.hex --force
RUN mix local.rebar --force
RUN mix deps.get

CMD ["/app/docker_dev/entrypoint.sh"]