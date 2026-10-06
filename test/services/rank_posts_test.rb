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

  # ---- Phase 4c: who wrote it, where, which company ----

  def vancouver_profile
    Domain::UserProfile.from_h(
      name: "Pedro", job_targets: [{ name: "UI/UX Design", terms: ["ux designer"] }],
      locations: ["Vancouver"], target_companies: ["Acme Design"]
    )
  end

  def rank_with(profile, *posts)
    Services::RankPosts.new.call(posts: posts.map { Domain::CapturedPost.new(**_1) }, profile:)
  end

  def test_recruiter_post_ranks_even_without_job_words
    first = rank_with(vancouver_profile, { text: "Tips for a strong first week at a new job", author_headline: "Senior Talent Acquisition Partner" }).first

    assert_equal "recruiter", first.author_type
    assert_equal 4, first.score
    assert_equal "Recruiter", first.reason
  end

  def test_hiring_manager_in_vancouver_at_target_company_beats_a_peer_saying_the_same
    same = "Our team is hiring a UX designer. Apply now!"
    ranked = rank_with(vancouver_profile,
                       { text: same, author: "Peer", author_headline: "UX Designer" },
                       { text: "#{same} Based in Vancouver.", author: "Maya", author_headline: "Design Manager at Acme Design" })

    best, peer = ranked
    assert_equal "Maya", best.post.author
    assert_equal "hiring_manager", best.author_type
    assert_equal ["Acme Design"], best.matched_companies
    assert_equal ["Vancouver"], best.matched_locations
    assert_equal 3 + 5 + 4 + 3 + 2, best.score
    assert_equal "Hiring manager · Job opening · Acme Design · Vancouver · UI/UX Design", best.reason
    assert_nil peer.author_type
  end

  def test_company_page_counts_as_target_company_by_author_name
    first = rank_with(vancouver_profile, { text: "Our design culture", author: "Acme Design" }).first

    assert_equal ["Acme Design"], first.matched_companies
  end

  def test_profile_without_audiences_uses_defaults
    assert_equal %w[recruiter hiring_manager bubble], profile.audiences.map(&:type)
  end

  def test_custom_audiences_from_profile_keep_their_order
    custom = Domain::UserProfile.from_h(name: "P", audiences: [{ type: "mentor", terms: ["mentor"] }])
    audience = Text::AuthorClassifier.new.call(headline: "UX Mentor", audiences: custom.audiences)

    assert_equal "mentor", audience.type
    assert_equal "Mentor", audience.label
  end
end
