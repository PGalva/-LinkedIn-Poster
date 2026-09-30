# frozen_string_literal: true

require_relative "../test_helper"

class HashtagGeneratorTest < Minitest::Test
  include TestSupport

  def generator = Text::HashtagGenerator.new(limit: 5)

  def test_camel_cases_and_strips_accents
    assert_equal ["#DesignSystem", "#Acessibilidade", "#RubyOnRails"],
                 generator.call(["design system", "acessibilidade", "ruby on rails"])
  end

  def test_keeps_acronyms_and_existing_hash
    assert_equal ["#UX", "#iOS"], generator.call(["#UX", "iOS"])
  end

  def test_dedupes_ignoring_case_and_accents_and_respects_priority
    assert_equal ["#Programacao"], generator.call(["programação"], ["#PROGRAMACAO"])
  end

  def test_limits_and_drops_garbage
    tags = generator.call(%w[a b1 c2 d3 e4 f5 g6], ["", nil, "2026", "!!!"])
    assert_equal 5, tags.size
    refute_includes tags, "#2026"
  end
end

class KeywordExtractorTest < Minitest::Test
  include TestSupport

  def extractor = Text::KeywordExtractor.new

  def test_top_keywords_ignore_stopwords_and_accents
    text = "Design system em React. O design system é a base; React ajuda na acessibilidade."
    assert_equal %w[design react system], extractor.call(text, limit: 3)
  end

  def test_matches_multi_word_terms_with_boundaries
    text = "Vaga para UX Engineer: cuidar do Design System"
    assert_equal ["UX Engineer", "design system"], extractor.matches(text, ["UX Engineer", "design system", "Ruby"])
  end

  def test_does_not_match_inside_other_words
    assert_empty extractor.matches("Rubyist convention", ["Ruby"])
  end
end

class ResponseParserTest < Minitest::Test
  include TestSupport

  def parser = Text::ResponseParser.new

  def test_parses_json_inside_markdown_fence
    text = "Aqui está:\n```json\n{\"comment\": \"oi\"}\n```"
    assert_equal({ "comment" => "oi" }, parser.parse_json(text, required_keys: %w[comment]))
  end

  def test_parses_bare_json_with_preamble
    assert_equal "oi", parser.parse_json('Claro! {"comment": "oi"}')["comment"]
  end

  def test_missing_keys_raise
    assert_raises(LLM::InvalidResponseError) { parser.parse_json('{"x": 1}', required_keys: %w[comment]) }
  end

  def test_no_json_raises
    assert_raises(LLM::InvalidResponseError) { parser.parse_json("desculpe, não posso") }
  end
end
