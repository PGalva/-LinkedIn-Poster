# frozen_string_literal: true

require_relative "../test_helper"

class RankPostsTest < Minitest::Test
  include TestSupport

  def rank(*texts, limit: 10)
    posts = texts.map { Domain::CapturedPost.new(text: _1) }
    Services::RankPosts.new.call(posts:, profile:, limit:)
  end

  def test_job_opening_for_a_target_beats_a_topic_post
    ranked = rank(
      "Five tips on React performance and design system tokens",
      "We're hiring a UX Designer! Apply now",
      "Carrot cake recipe"
    )

    assert_equal 2, ranked.size
    first = ranked.first
    assert first.job_opening
    assert_equal ["UI/UX Design"], first.matched_targets
    assert_equal 8, first.score # 3 (target) + 5 (hiring)
  end

  def test_coop_ux_role_matches_two_targets
    first = rank("Estamos contratando estágio / co-op em UX/UI design. Vaga remota.").first

    assert_equal ["UI/UX Design", "Co-op"], first.matched_targets
    assert first.job_opening
    assert_equal 11, first.score # 3 + 3 + 5
    assert_equal "Job opening · UI/UX Design, Co-op", first.reason
  end

  def test_hiring_post_for_another_role_is_not_a_job_opening_for_you
    assert_empty rank("We're hiring an accountant. Apply now!")
  end

  def test_topic_post_without_hiring_has_no_bonus
    first = rank("What makes a great UX designer portfolio? Use React and Figma").first

    refute first.job_opening
    assert_equal 4, first.score # 3 (target) + 1 (React keyword)
    assert_equal ["React"], first.matched_keywords
  end

  def test_limit
    texts = Array.new(5) { "Hiring a product designer ##{_1}" }
    assert_equal 2, rank(*texts, limit: 2).size
  end

  def test_profile_still_accepts_plain_target_roles
    old = Domain::UserProfile.from_h(name: "P", target_roles: ["UX Engineer"])

    assert_equal ["UX Engineer"], old.target_roles
    assert_equal ["UX Engineer"], old.job_targets.first.terms
  end
end
