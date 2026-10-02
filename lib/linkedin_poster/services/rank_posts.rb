# frozen_string_literal: true

module LinkedinPoster
  module Services
    # Use case: "which feed posts are about the jobs I want to apply for?"
    #
    # No AI here: explicit, cheap rules that run on EVERY post in the feed.
    # The AI is only called later, for the posts the user picks.
    #
    # Score:
    #   +3 per job target mentioned        ("UX designer" -> UI/UX Design)
    #   +5 if it is also a hiring post     ("we're hiring", "vaga", "apply now")
    #   +1 per profile keyword mentioned   ("React", "Figma")
    #
    # The hiring bonus only counts when a target matched: "we're hiring a
    # accountant" is a job post, just not one for you.
    class RankPosts
      TARGET_WEIGHT = 3
      HIRING_BONUS = 5
      KEYWORD_WEIGHT = 1

      HIRING_SIGNALS = [
        # English
        "hiring", "we're hiring", "we are hiring", "join our team", "open role", "open roles",
        "open position", "job opening", "now accepting applications", "apply now", "how to apply",
        "apply here", "link to apply", "recruiting", "looking for a", "looking for an",
        # Portuguese
        "contratando", "estamos contratando", "vaga", "vagas", "oportunidade de",
        "candidate-se", "processo seletivo", "estamos buscando", "procuramos"
      ].freeze

      def initialize(extractor: Text::KeywordExtractor.new, hiring_signals: HIRING_SIGNALS)
        @extractor = extractor
        @hiring_signals = hiring_signals
      end

      def call(posts:, profile:, limit: 10)
        posts
          .map { rank(_1, profile) }
          .select { _1.score.positive? }
          .sort_by { [-_1.score, _1.job_opening ? 0 : 1] }
          .first(limit)
      end

      private

      def rank(post, profile)
        targets = profile.job_targets.select { |t| @extractor.matches(post.text, t.terms).any? }
        job_opening = targets.any? && @extractor.matches(post.text, @hiring_signals).any?
        keywords = @extractor.matches(post.text, profile.keywords)

        score = (targets.size * TARGET_WEIGHT) +
                (job_opening ? HIRING_BONUS : 0) +
                (keywords.size * KEYWORD_WEIGHT)

        Domain::RankedPost.new(
          post:, score:, job_opening:,
          matched_targets: targets.map(&:name),
          matched_keywords: keywords
        )
      end
    end
  end
end
