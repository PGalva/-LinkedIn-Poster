# frozen_string_literal: true

module LinkedinPoster
  module Domain
    # Who the user is and which jobs they are after. Loaded from config/profile.yml,
    # which is written FROM the user's resume: the resume is the source of truth.
    #
    # highlights: true facts the AI may cite ("5+ years in backend: Rails, Java").
    #   The AI is told to mention ONLY these — without them, it invents experience.
    # audiences:  the kinds of post authors you want to be seen by (recruiters, hiring
    #   managers, references in your field). Defaults to Audience.defaults.
    # locations / target_companies: where you want to work; posts that mention them rank higher.
    #
    # Why Data.define? Immutable value objects: once built, no service can
    # change the profile "by accident" halfway through a request.
    UserProfile = Data.define(:name, :headline, :job_targets, :keywords, :highlights, :tone, :language,
                              :audiences, :locations, :target_companies) do
      def self.from_h(hash)
        h = hash.transform_keys(&:to_sym)
        new(
          name: h.fetch(:name),
          headline: h.fetch(:headline, ""),
          job_targets: parse_job_targets(h),
          keywords: Array(h[:keywords]),
          highlights: list(h[:highlights]),
          tone: h.fetch(:tone, "professional and approachable"),
          language: h.fetch(:language, "en-US"),
          audiences: h[:audiences] ? Array(h[:audiences]).map { Audience.from_h(_1) } : Audience.defaults,
          locations: list(h[:locations]),
          target_companies: list(h[:target_companies])
        )
      end

      def self.list(value) = Array(value).map { _1.to_s.strip }.reject(&:empty?)

      # Accepts the new `job_targets:` list, or the older `target_roles:` list of
      # plain strings (each role becomes a target with no extra terms).
      def self.parse_job_targets(h)
        if h[:job_targets]
          Array(h[:job_targets]).map { JobTarget.from_h(_1) }
        else
          Array(h[:target_roles]).map { JobTarget.new(name: _1) }
        end
      end

      # Target names, for prompts ("UI/UX Design, Co-op, Developer").
      def target_roles = job_targets.map(&:name)
    end
  end
end
