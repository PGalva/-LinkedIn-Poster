# frozen_string_literal: true

module LinkedinPoster
  module Services
    # Use case: "from the brief, write a post + hashtags, and review it for engagement".
    class GeneratePost
      MAX_POST_CHARS = 3_000 # LinkedIn's limit for posts
      MAX_HOOKS = 2

      def initialize(llm:,
                     prompt_builder: Prompts::PostPromptBuilder.new,
                     parser: Text::ResponseParser.new,
                     hashtags: Text::HashtagGenerator.new(limit: 5),
                     engagement: Text::EngagementCheck.new,
                     language_detector: Text::LanguageDetector.new)
        @llm = llm
        @prompt_builder = prompt_builder
        @parser = parser
        @hashtags = hashtags
        @engagement = engagement
        @language_detector = language_detector
      end

      def call(brief:, profile:)
        # Write in the language of the idea you typed (falls back to the profile's).
        language = @language_detector.language_name([brief.idea, brief.goal].compact.join(" ")) || profile.language
        response = @llm.complete(@prompt_builder.build(brief:, profile:, language:))
        data = @parser.parse_json(response.text, required_keys: %w[body])

        # Priority: topics you chose > AI suggestions > profile keywords
        tags = @hashtags.call(brief.topics, Array(data["hashtags"]), profile.keywords)
        body = fit_to_limit(strip_trailing_hashtags(data["body"]), tags)

        Domain::GeneratedPost.new(
          body:,
          hashtags: tags,
          hooks: clean_hooks(data["hooks"]),
          checks: @engagement.call(body:, hashtags: tags),
          provider: response.provider
        )
      end

      private

      # If the AI disobeys and puts hashtags at the end of the body, remove them.
      def strip_trailing_hashtags(body)
        body.to_s.sub(/(\s*#[\p{L}\p{N}_]+)+\s*\z/, "").strip
      end

      def clean_hooks(hooks)
        Array(hooks).filter_map { _1.is_a?(String) ? _1.strip.lines.first&.strip : nil }
                    .reject(&:empty?).uniq.first(MAX_HOOKS)
      end

      def fit_to_limit(body, tags)
        room = MAX_POST_CHARS - tags.join(" ").length - 2
        body.length > room ? "#{body[0, room - 1].rstrip}…" : body
      end
    end
  end
end
