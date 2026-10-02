# frozen_string_literal: true

Rails.application.routes.draw do
  get  "/health",           to: "health#show"
  post "/comments/suggest", to: "comments#suggest"
  post "/posts/generate",   to: "posts#generate"
  post "/posts/rank",       to: "posts#rank"
end
