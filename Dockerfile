# Dockerfile.build
FROM elixir:alpine as builder

# prevents running the below commands in the top level directory to avoid conflicts
WORKDIR /opt/app

RUN mix local.hex --force && \
    mix local.rebar --force

ENV MIX_ENV=prod REPLACE_OS_VARS=true

# first path is relative to the build context (i.e. if you're in the project dir and execute
# docker build . then it ./ will refer to budget_app project dir)
# second path is the place to copy the stuff inside the container
COPY ./mix.exs ./mix.lock ./

# Install some dependencies
RUN mix deps.get --only prod

COPY config ./config
RUN MIX_ENV=prod mix deps.compile

COPY ./ ./

RUN mix release --env=prod

# Dockerfile.release
FROM elixir:alpine

RUN apk add bash

ENV REPLACE_OS_VARS=true
ENV MIX_ENV=prod

WORKDIR /opt/app
# COPY ./budget_app.tar.gz ./
COPY --from=builder /opt/app/_build/prod/rel/budget_app ./

# RUN tar xfz budget_app.tar.gz
ENV REPLACE_OS_VARS=true
EXPOSE 80

ENTRYPOINT ["/opt/app/bin/budget_app"]
CMD ["foreground"]