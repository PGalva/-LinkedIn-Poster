# frozen_string_literal: true

Rails.application.routes.draw do
  get  "/health",           to: "health#show"
  post "/comments/suggest", to: "comments#suggest"
  post "/posts/generate",   to: "posts#generate"
  post "/posts/check",      to: "posts#check"
  post "/posts/rank",       to: "posts#rank"

  # Local playground for the extension's content script (development only).
  if Rails.env.development?
    get "/dev/feed",                 to: "dev#feed"
    get "/dev/extension/:file",      to: "dev#extension_file", constraints: { file: /[\w.-]+/ }, format: false
  end
end
