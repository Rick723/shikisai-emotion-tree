FROM ruby:3.4.10

WORKDIR /app

RUN apt-get update -qq && \
    apt-get install --no-install-recommends -y \
      build-essential \
      default-libmysqlclient-dev \
      pkg-config && \
    rm -rf /var/lib/apt/lists/*

COPY Gemfile Gemfile.lock ./

RUN bundle install

CMD ["bash"]
