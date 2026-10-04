# frozen_string_literal: true

require_relative "../test_helper"

class EngagementCheckTest < Minitest::Test
  include TestSupport

  def checker = Text::EngagementCheck.new
  def result(body, hashtags = %w[#UX #Design #A11y]) = checker.call(body:, hashtags:).to_h { [_1.id, _1] }

  GOOD = <<~POST.strip
    I spent five years making APIs fast. Nobody ever thanked the API.

    Then I watched a user look for the save button for two full minutes. The API behind it answered in 40 ms. It didn't matter.

    That was the day I understood that speed nobody can see is not a feature. The interface is the product people actually meet.

    So I went back to school for UX/UI design, and now I spend my days on usability tests, flows and design systems.

    The backend years still help: I know what is cheap to build and what is not, and I can talk to engineers in their own words.

    What was the moment that changed your career direction?
  POST

  def test_a_good_post_passes_everything
    failed = result(GOOD).values.reject(&:passed).map(&:id)
    assert_empty failed
  end

  def test_long_hook_fails_with_a_tip
    check = result("#{'word ' * 40}\n\nWhat do you think about it?")["hook"]
    refute check.passed
    assert_match(/150/, check.tip)
  end

  def test_needs_a_closing_question
    refute result(GOOD.sub("career direction?", "career direction."))["question"].passed
  end

  def test_links_in_body_fail
    refute result("#{GOOD}\n\nhttps://example.com")["no_links"].passed
  end

  def test_engagement_bait_fails
    refute result("#{GOOD}\n\nComment YES if you agree")["no_bait"].passed
    refute result("#{GOOD}\n\nMarque alguém que precisa ler isso")["no_bait"].passed
  end

  def test_hashtag_count
    refute result(GOOD, %w[#UX])["hashtags"].passed
    assert result(GOOD, %w[#UX #A #B #C #D])["hashtags"].passed
  end

  def test_long_paragraph_fails
    refute result("Hook\n\n#{'a' * 301}\n\nQuestion?")["paragraphs"].passed
  end
end
