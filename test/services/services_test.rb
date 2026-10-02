# frozen_string_literal: true

require_relative "../test_helper"

# Os serviços são testados com o adapter Fake: rápidos, sem rede, sem custo.
class SuggestCommentTest < Minitest::Test
  include TestSupport

  def test_returns_sanitized_suggestion
    llm = LLM::Adapters::Fake.new(responses: [
      %(```json\n{"comment": "Concordo! Em design system, tokens salvam tempo. #UX #Design", "angle": "insight"}\n```)
    ])

    result = Services::SuggestComment.new(llm:).call(post: captured_post, profile:)

    assert_equal "Concordo! Em design system, tokens salvam tempo.", result.text
    assert_equal "insight", result.angle
    assert_equal "fake", result.provider
  end

  def test_prompt_contains_post_and_profile
    llm = LLM::Adapters::Fake.new
    Services::SuggestComment.new(llm:).call(post: captured_post, profile:)

    prompt = llm.prompts.last
    assert_includes prompt.user, "<post>"
    assert_includes prompt.user, "design system em React"
    assert_includes prompt.system, "Pedro"
  end

  def test_llm_errors_bubble_up_as_llm_errors
    llm = LLM::Adapters::Fake.new(error: LLM::RateLimitedError.new("calma"))
    assert_raises(LLM::RateLimitedError) { Services::SuggestComment.new(llm:).call(post: captured_post, profile:) }
  end

  def test_empty_post_is_rejected_by_domain
    assert_raises(ValidationError) { Domain::CapturedPost.new(text: "   ") }
  end
end

class GeneratePostTest < Minitest::Test
  include TestSupport

  def brief
    Domain::PostBrief.new(goal: "mostrar que busco vaga de UX Engineer", topics: ["design system", "acessibilidade"])
  end

  def test_builds_body_and_prioritized_hashtags
    llm = LLM::Adapters::Fake.new(responses: [
      %({"body": "Gancho forte.\\n\\nConteúdo.\\n\\n#spam #extra", "hashtags": ["UX", "Frontend", "design system"]})
    ])

    post = Services::GeneratePost.new(llm:).call(brief:, profile:)

    assert_equal "Gancho forte.\n\nConteúdo.", post.body
    assert_equal ["#DesignSystem", "#Acessibilidade", "#UX", "#Frontend", "#React"], post.hashtags
    assert_includes post.to_text, "#DesignSystem #Acessibilidade"
  end

  def test_brief_requires_topics
    assert_raises(ValidationError) { Domain::PostBrief.new(goal: "x", topics: []) }
  end
end
