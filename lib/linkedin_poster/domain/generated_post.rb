# frozen_string_literal: true

module LinkedinPoster
  module Domain
    # Result of GeneratePost. Body and hashtags stay separate so the UI can edit each part.
    #
    # - hooks:  alternative first lines suggested by the AI (pick one to swap the opening)
    # - checks: engagement checklist (Text::EngagementCheck) — rules, not AI
    GeneratedPost = Data.define(:body, :hashtags, :hooks, :checks, :provider) do
      def initialize(body:, hashtags:, provider:, hooks: [], checks: [])
        super
      end

      def to_text
        [body, hashtags.join(" ")].reject(&:empty?).join("\n\n")
      end

      # Data#to_h is shallow; make the checks JSON-friendly too.
      def to_h
        super.merge(checks: checks.map(&:to_h))
      end
    end
  end
end
