# frozen_string_literal: true

module LinkedinPoster
  module Text
    # Engagement checklist for a LinkedIn post — plain rules, no AI.
    #
    # These are widely shared rules of thumb about what makes people stop, read and
    # comment. They are NOT guarantees of reach: treat them as a review checklist.
    # Phase 5 (history) is where we'll measure what actually works for YOU.
    #
    # Why not ask the AI "is this engaging?": rules are instant, free, testable and
    # always give the same answer. The AI writes; the rules review.
    class EngagementCheck
      Result = Data.define(:id, :label, :passed, :tip)

      HOOK_MAX = 150        # LinkedIn shows ~2 lines before "…see more"; the hook must fit there
      PARAGRAPH_MAX = 300   # walls of text get skipped on mobile
      LENGTH = (600..1_300) # long enough to say something, short enough to finish
      HASHTAGS = (3..5)
      LINK = %r{https?://|www\.}i
      BAIT = /\b(comment\s+["'“]?(yes|sim|interested|eu quero)|like if|curta se|tag (a friend|someone)|marque (um amigo|algu[eé]m))\b/i

      def call(body:, hashtags: [])
        text = body.to_s.strip
        paragraphs = text.split(/\n\s*\n/).map(&:strip).reject(&:empty?)
        hook = text.lines.first.to_s.strip

        [
          check(:hook, "Hook fits before '…see more'", hook.length.between?(1, HOOK_MAX),
                "Keep the first line under #{HOOK_MAX} characters and make it specific."),
          check(:question, "Ends with a question", paragraphs.last.to_s.include?("?"),
                "Close with one specific question people can answer from their own experience."),
          check(:paragraphs, "Short paragraphs", paragraphs.all? { _1.length <= PARAGRAPH_MAX },
                "Break paragraphs longer than #{PARAGRAPH_MAX} characters; most people read on a phone."),
          check(:length, "#{LENGTH.min}–#{LENGTH.max} characters", LENGTH.cover?(text.length),
                "Aim for #{LENGTH.min}–#{LENGTH.max} characters (now #{text.length})."),
          check(:no_links, "No links in the body", !text.match?(LINK),
                "Put the link in the first comment instead; posts with external links tend to get less reach."),
          check(:hashtags, "#{HASHTAGS.min}–#{HASHTAGS.max} hashtags", HASHTAGS.cover?(Array(hashtags).size),
                "Use #{HASHTAGS.min} to #{HASHTAGS.max} specific hashtags."),
          check(:no_bait, "No engagement bait", !text.match?(BAIT),
                "Avoid 'comment YES' / 'tag a friend' — LinkedIn demotes it and it reads as spam.")
        ]
      end

      private

      def check(id, label, passed, tip)
        Result.new(id: id.to_s, label:, passed: passed ? true : false, tip: passed ? nil : tip)
      end
    end
  end
end
