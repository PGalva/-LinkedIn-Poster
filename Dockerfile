# LinkedIn Poster API image.
# Recipe: "take a Linux with Ruby, install the gems, copy the code, start the server".
FROM ruby:3.3-slim

# puma, nio4r and some Rails dependencies compile C extensions -> need a compiler.
RUN apt-get update \
 && apt-get install -y --no-install-recommends build-essential libyaml-dev \
 && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Match the Bundler version that wrote Gemfile.lock.
RUN gem update --system --no-document && gem install bundler:4.0.3 --no-document

# Copy ONLY the Gemfile first: Docker caches this step, so gems are not
# reinstalled every time you change a line of code.
COPY Gemfile Gemfile.lock* ./
RUN bundle install

COPY . .

EXPOSE 9292

# -b 0.0.0.0 is required: without it the server only listens *inside* the
# container and your browser/curl can't reach it.
# The pid file lives in /tmp so a crashed container never leaves a stale one in your folder.
CMD ["bin/rails", "server", "-b", "0.0.0.0", "-p", "9292", "-P", "/tmp/server.pid"]
