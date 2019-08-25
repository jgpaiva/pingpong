FROM elixir:1.9.0

ENV APP_HOME /pingpong
WORKDIR $APP_HOME

COPY mix.exs $APP_HOME/
COPY mix.lock $APP_HOME/

RUN mix local.hex --force
RUN mix local.rebar --force
RUN mix deps.get

COPY . $APP_HOME/

RUN mix test

RUN mix escript.build

ENTRYPOINT ["./docker-entrypoint.sh"]
