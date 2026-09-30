# frozen_string_literal: true

source "https://rubygems.org"

ruby ">= 3.2" # Data.define

# Só a camada HTTP usa gems. O núcleo (lib/) é Ruby puro.
gem "dotenv"
gem "puma"
gem "rackup"
gem "sinatra"

group :test do
  gem "minitest"
  gem "rack-test"
  gem "rake"
end
