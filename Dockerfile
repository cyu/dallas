FROM ruby:alpine

RUN apk update && apk add build-base postgresql-dev libffi-dev

RUN mkdir /app
ADD Gemfile Gemfile.lock config.ru dallas.rb /app/
ADD lib /app/lib
WORKDIR /app

RUN gem install bundler --no-ri --no-rdoc
RUN bundle install --system

ENV ENVIRONMENT production

EXPOSE 8080

CMD ["bundle", "exec", "thin", "-p", "8080", "-e", "echo ${ENVIRONMENT}", "-R", "config.ru", "start"]
