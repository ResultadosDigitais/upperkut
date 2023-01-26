FROM ruby:3.2

WORKDIR /code
COPY . .

RUN gem install bundler
RUN bundle install