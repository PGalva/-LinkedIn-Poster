# frozen_string_literal: true

require_relative "../test_helper"

# Garante que o modo offline (LLM_PROVIDER=fake) atende TODOS os serviços.
class FakeOfflineModeTest < Minitest::Test
  include TestSupport

  def test_offline_fake_serves_suggest_comment
    result = Services::SuggestComment.new(llm: LLM.build("fake")).call(post: captured_post, profile:)

    assert_match(/\[offline\].*contratando UX Engineer/, result.text)
  end

  def test_offline_fake_serves_generate_post
    brief = Domain::PostBrief.new(goal: "buscar vaga", topics: ["design system"])
    post = Services::GeneratePost.new(llm: LLM.build("fake")).call(brief:, profile:)

    assert_match(/design system/, post.body)
    assert_equal "#DesignSystem", post.hashtags.first
  end
end
