# frozen_string_literal: true

module LinkedinPoster
  module Prompts
    # Builds the Post Creator prompt from the form (Goal, Audience, Tone, Topics)
    # plus the user's profile.
    class PostPromptBuilder
      # Bump on every prompt change so Prompt Lab runs can be compared by version.
      # v2: cite only profile highlights; no invented stories.
      VERSION = 2

      def build(brief:, profile:)
        Domain::Prompt.new(
          system: system_prompt(profile),
          user: user_prompt(brief, profile),
          max_tokens: 1_200,
          temperature: 0.8
        )
      end

      private

      def system_prompt(profile)
        <<~PROMPT
          You are a LinkedIn copywriter for #{profile.name} (#{profile.headline}).

          Post rules:
          - Write in #{profile.language}.
          - The first line is a strong hook (no clickbait).
          - Short paragraphs (1 to 3 lines), 600 to 1300 characters in total.
          - End with a call to action that fits the goal.
          - Use ONLY the facts listed under "Facts about the author" for experience, companies,
            numbers and stories. Never invent anything beyond them.
          - Do NOT put hashtags in the body; suggest them separately.

          Reply ONLY with JSON in this format:
          {"body": "post text", "hashtags": ["term1", "term2", "term3"]}
        PROMPT
      end

      def user_prompt(brief, profile)
        facts = profile.highlights.empty? ? "- (none provided)" : profile.highlights.map { "- #{_1}" }.join("\n")

        <<~PROMPT
          Goal: #{brief.goal}
          Audience: #{brief.audience}
          Tone: #{brief.tone || profile.tone}
          Topics: #{brief.topics.join(', ')}
          Roles the author is applying for: #{profile.target_roles.join(', ')}

          Facts about the author:
          #{facts}
        PROMPT
      end
    end
  end
end
