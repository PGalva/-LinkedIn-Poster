# frozen_string_literal: true

source "https://rubygems.org"

ruby ">= 3.2" # Data.define

# Only the HTTP layer uses gems. The core (lib/) is plain Ruby.
gem "rails", "~> 8.0"
gem "puma"
gem "dotenv" # loads .env automatically under Rails

group :test do
  gem "minitest", "~> 5.25" # Rails 8.0's test helpers expect Minitest 5
  gem "rake"
end
