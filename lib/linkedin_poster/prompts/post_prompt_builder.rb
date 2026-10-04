# frozen_string_literal: true

module LinkedinPoster
  module Prompts
    # Builds the Post Creator prompt from the brief (idea, goal, audience, tone, topics)
    # plus the user's profile.
    class PostPromptBuilder
      # Bump on every prompt change so Prompt Lab runs can be compared by version.
      # v2: cite only profile highlights; no invented stories.
      # v3: the author's own idea is the core; engagement rules (hook before "…see more",
      #     one idea, closing question, no links); 2 alternative hooks; post's language.
      VERSION = 3

      def build(brief:, profile:, language: profile.language)
        Domain::Prompt.new(
          system: system_prompt(profile, language),
          user: user_prompt(brief, profile),
          max_tokens: 900, # ~1300 chars + 2 hooks + hashtags; a lower cap = faster local models
          temperature: 0.8
        )
      end

      private

      def system_prompt(profile, language)
        <<~PROMPT
          You are a LinkedIn ghostwriter for #{profile.name} (#{profile.headline}).
          Your job: turn what the author wants to say into a post people stop to read and want to answer.

          Post rules:
          - Write in #{language}. Sound like a person talking, not a press release.
          - If the author gave an idea, it is the core of the post: keep its meaning and point of view.
          - First line = the hook, under 150 characters: a specific claim, number, tension or moment.
            No clickbait, no "I'm excited to announce", no questions like "Did you know...?".
          - One idea per post. Short paragraphs (1 to 3 lines) separated by a blank line.
          - 600 to 1300 characters in total.
          - Show, don't tell: one concrete detail or moment beats adjectives.
          - End with ONE specific question the audience can answer from their own experience
            (not "What do you think?" and never "comment YES" or "tag a friend").
          - Use ONLY the facts listed under "Facts about the author" for experience, companies,
            numbers and stories. Never invent anything beyond them.
          - No links and no hashtags in the body; suggest hashtags separately.
          - Also suggest 2 alternative hooks (other first lines for the same post).

          Reply ONLY with JSON in this format:
          {"body": "post text", "hooks": ["alternative first line", "another one"], "hashtags": ["term1", "term2", "term3"]}
        PROMPT
      end

      def user_prompt(brief, profile)
        facts = profile.highlights.empty? ? "- (none provided)" : profile.highlights.map { "- #{_1}" }.join("\n")
        lines = []
        lines << "What the author wants to say (their own words):\n<idea>\n#{brief.idea}\n</idea>" if brief.idea
        lines << "Goal: #{brief.goal}" if brief.goal
        lines << "Audience: #{brief.audience}"
        lines << "Tone: #{brief.tone || profile.tone}"
        lines << "Topics: #{brief.topics.join(', ')}" if brief.topics.any?
        lines << "Roles the author is applying for: #{profile.target_roles.join(', ')}"

        <<~PROMPT
          #{lines.join("\n")}

          Facts about the author:
          #{facts}
        PROMPT
      end
    end
  end
end
