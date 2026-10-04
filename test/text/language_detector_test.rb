# frozen_string_literal: true

require_relative "../test_helper"

class LanguageDetectorTest < Minitest::Test
  include TestSupport

  def detector = Text::LanguageDetector.new

  def test_detects_english
    assert_equal "en", detector.call("We are hiring a UX Designer co-op for our design system team. Apply now!")
    assert_equal "English", detector.language_name("Who owns the documentation on your team?")
  end

  def test_detects_portuguese
    assert_equal "pt", detector.call("Vaga de estágio em UX/UI Design! Buscamos alguém com conhecimento em Figma.")
    assert_equal "Portuguese", detector.language_name("Estamos contratando para o nosso time de produto")
  end

  def test_returns_nil_when_unsure
    assert_nil detector.call("Figma React UX")
    assert_nil detector.call("")
  end
end

class CommentLanguageAndFactsTest < Minitest::Test
  include TestSupport

  def test_english_post_gets_english_prompt_even_with_portuguese_profile_language
    llm = LLM::Adapters::Fake.new
    pt_profile = Domain::UserProfile.from_h(name: "Pedro", language: "pt-BR", highlights: ["Rails at ZeeNow"])
    post = Domain::CapturedPost.new(text: "We are hiring a UX Designer for our team. Apply now!")

    Services::SuggestComment.new(llm:).call(post:, profile: pt_profile)

    assert_includes llm.prompts.last.system, "Write in English"
  end

  def test_unclear_language_falls_back_to_profile
    llm = LLM::Adapters::Fake.new
    profile = Domain::UserProfile.from_h(name: "Pedro", language: "pt-BR")

    Services::SuggestComment.new(llm:).call(post: Domain::CapturedPost.new(text: "Figma React UX"), profile:)

    assert_includes llm.prompts.last.system, "Write in pt-BR"
  end

  def test_prompt_lists_only_the_profile_highlights_as_citable_facts
    prompt = Prompts::CommentPromptBuilder.new.build(post: captured_post, profile:)

    assert_includes prompt.user, "- 5+ years in backend development (Rails, Java)"
    assert_includes prompt.system, "mention ONLY facts"
  end

  def test_profile_without_highlights_forbids_experience_claims
    bare = Domain::UserProfile.from_h(name: "Pedro")
    prompt = Prompts::CommentPromptBuilder.new.build(post: captured_post, profile: bare)

    assert_includes prompt.user, "do not mention any experience"
  end
end
