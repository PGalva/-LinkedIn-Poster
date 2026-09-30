# frozen_string_literal: true

require "dotenv/load" # carrega o .env
require_relative "app/api"

run Api
