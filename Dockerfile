FROM ruby:2.7.2

WORKDIR /code
COPY . .

RUN gem install bundler
RUN bundle install