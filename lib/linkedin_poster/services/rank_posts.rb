# frozen_string_literal: true

module LinkedinPoster
  module Services
    # Use case: "which feed posts help me get seen by people who can hire me?"
    #
    # No AI here: explicit, cheap rules that run on EVERY post in the feed.
    # The AI is only called later, for the posts the user picks.
    #
    # Score — WHAT the post says:
    #   +3 per job target mentioned        ("UX designer" -> UI/UX Design)
    #   +5 if it is also a hiring post     ("we're hiring", "vaga", "apply now")
    #   +1 per profile keyword mentioned   ("React", "Figma")
    # Score — WHO wrote it and WHERE (Phase 4c):
    #   +4 recruiter · +4 hiring manager · +2 reference in your field   (from the author's headline)
    #   +3 per target company mentioned    (in the text, author name or headline)
    #   +2 per location mentioned          ("Vancouver")
    #
    # The hiring bonus only counts when a target matched: "we're hiring an
    # accountant" is a job post, just not one for you.
    class RankPosts
      TARGET_WEIGHT = 3
      HIRING_BONUS = 5
      KEYWORD_WEIGHT = 1
      AUDIENCE_WEIGHTS = { "recruiter" => 4, "hiring_manager" => 4, "bubble" => 2 }.freeze
      DEFAULT_AUDIENCE_WEIGHT = 2 # custom audience types from profile.yml
      COMPANY_WEIGHT = 3
      LOCATION_WEIGHT = 2

      HIRING_SIGNALS = [
        # English
        "hiring", "we're hiring", "we are hiring", "join our team", "open role", "open roles",
        "open position", "job opening", "now accepting applications", "apply now", "how to apply",
        "apply here", "link to apply", "recruiting", "looking for a", "looking for an",
        # Portuguese
        "contratando", "estamos contratando", "vaga", "vagas", "oportunidade de",
        "candidate-se", "processo seletivo", "estamos buscando", "procuramos"
      ].freeze

      def initialize(extractor: Text::KeywordExtractor.new,
                     classifier: Text::AuthorClassifier.new,
                     hiring_signals: HIRING_SIGNALS)
        @extractor = extractor
        @classifier = classifier
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

        audience = @classifier.call(headline: post.author_headline, audiences: profile.audiences)
        about = [post.text, post.author, post.author_headline].compact.join("\n")
        companies = @extractor.matches(about, profile.target_companies)
        locations = @extractor.matches(about, profile.locations)

        score = (targets.size * TARGET_WEIGHT) +
                (job_opening ? HIRING_BONUS : 0) +
                (keywords.size * KEYWORD_WEIGHT) +
                audience_weight(audience) +
                (companies.size * COMPANY_WEIGHT) +
                (locations.size * LOCATION_WEIGHT)

        Domain::RankedPost.new(
          post:, score:, job_opening:,
          matched_targets: targets.map(&:name),
          matched_keywords: keywords,
          author_type: audience&.type,
          author_label: audience&.label,
          matched_locations: locations,
          matched_companies: companies
        )
      end

      def audience_weight(audience)
        return 0 unless audience

        AUDIENCE_WEIGHTS.fetch(audience.type, DEFAULT_AUDIENCE_WEIGHT)
      end
    end
  end
end
