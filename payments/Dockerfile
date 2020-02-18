FROM ruby:2.7.0-slim AS pre-builder

RUN /usr/bin/apt-get update \
    && /usr/bin/apt-get -y install build-essential

COPY Gemfile* ./
RUN bundle install

RUN rm -rf ${GEM_HOME}/cache/*.gem \
    && find ${GEM_HOME}/gems/ -name "*.c" -delete \
    && find ${GEM_HOME}/gems/ -name "*.o" -delete



FROM ruby:2.7.0-slim

ENV APP_HOME /usr/src/app
RUN mkdir -p ${APP_HOME}
WORKDIR ${APP_HOME}

COPY --from=pre-builder ${GEM_HOME} ${GEM_HOME}
COPY . ${APP_HOME}

ENV RAILS_ENV production
EXPOSE 3000

ENTRYPOINT ["bundle", "exec"]
CMD ["rails", "server"]
