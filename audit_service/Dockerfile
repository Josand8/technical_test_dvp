FROM ruby:3.4.3

WORKDIR /app

# Install build dependencies if needed, though Sinatra is light
RUN apt-get update -qq && apt-get install -y build-essential

# Copy Gemfile and install dependencies
COPY Gemfile* ./
RUN gem install bundler:2.4.19 && bundle install

# Copy application code
COPY . .