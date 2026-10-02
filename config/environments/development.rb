# frozen_string_literal: true

Rails.application.configure do
  # Controllers reload on every request: edit app/ and just refresh.
  # Changes in lib/ (the core) need a server restart: `docker compose restart api`.
  config.enable_reloading = true
  config.eager_load = false
  config.consider_all_requests_local = true
  config.server_timing = true
end
