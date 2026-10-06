# frozen_string_literal: true

require_relative "../test_helper"

class AuthorClassifierTest < Minitest::Test
  include TestSupport

  def type_of(headline) = Text::AuthorClassifier.new.call(headline:, audiences: Domain::Audience.defaults)&.type

  # Headlines in the shape the real feed shows them.
  def test_recognises_real_headline_shapes
    assert_equal "recruiter", type_of("Tech Recruiter | Hiring Designers & Engineers in Canada")
    assert_equal "recruiter", type_of("Recrutadora | Aquisição de Talentos | Tech")
    assert_equal "hiring_manager", type_of("Head of Design @ Acme · ex-Shopify")
    assert_equal "hiring_manager", type_of("Engineering Manager at a fintech")
    assert_equal "bubble", type_of("Senior Product Designer | Design Systems")
  end

  def test_peers_and_unknowns_are_nil
    assert_nil type_of("QA Analyst | Testes Manuais, API e Automação com Playwright/C#")
    assert_nil type_of("Software Engineer")
    assert_nil type_of(nil)
    assert_nil type_of("   ")
  end

  def test_first_match_wins_so_order_is_priority
    assert_equal "recruiter", type_of("Recruiter & UX Lead")
  end

  def test_captured_post_keeps_headline_optional_and_trimmed
    assert_nil Domain::CapturedPost.new(text: "hi", author_headline: "  ").author_headline
    assert_equal "Design Manager", Domain::CapturedPost.new(text: "hi", author_headline: " Design Manager ").author_headline
  end
end
