# frozen_string_literal: true

# End-to-end tests of the Rails API, offline: the Fake adapter answers.
ENV["RAILS_ENV"] = "test"
ENV["LLM_PROVIDER"] = "fake"
ENV["PROFILE_PATH"] = File.expand_path("../../config/profile.example.yml", __dir__)

require_relative "../../config/environment"
require "rails/test_help"

class ApiTest < ActionDispatch::IntegrationTest
  test "health reports the configured provider" do
    get "/health"

    assert_response :success
    assert_equal "fake", response.parsed_body["provider"]
  end

  test "suggests a comment" do
    post "/comments/suggest", params: { post: { text: "We're hiring a UX Designer", author: "Ana" } }, as: :json

    assert_response :success
    assert_match "[offline]", response.parsed_body["text"]
  end

  test "empty post is rejected with 422" do
    post "/comments/suggest", params: { post: { text: "" } }, as: :json

    assert_response 422
    assert_match "empty", response.parsed_body["error"]
  end

  test "generates a post with hashtags" do
    post "/posts/generate", params: { brief: { goal: "find a UX co-op", topics: ["design system"] } }, as: :json

    assert_response :success
    assert_equal "#DesignSystem", response.parsed_body["hashtags"].first
    assert_includes response.parsed_body["full_text"], "#DesignSystem"
  end

  test "ranks job openings for the target roles first" do
    post "/posts/rank", params: { posts: [
      { text: "Carrot cake recipe" },
      { text: "Tips for React developers" },
      { text: "We're hiring a UX Designer co-op. Apply now!" }
    ] }, as: :json

    assert_response :success
    first = response.parsed_body.first
    assert first["job_opening"]
    assert_match(/UX Designer co-op/, first["post"]["text"])
  end

  test "missing brief is rejected with 422" do
    post "/posts/generate", params: {}, as: :json

    assert_response 422
  end
end
