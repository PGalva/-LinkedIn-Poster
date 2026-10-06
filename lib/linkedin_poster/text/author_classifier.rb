# frozen_string_literal: true

module LinkedinPoster
  module Text
    # "Who wrote this post?" — from the author's headline, without AI.
    #
    #   classifier.call(headline: "Senior Talent Acquisition @ Acme", audiences: profile.audiences)
    #   # => Audience(type: "recruiter", ...)
    #
    # Returns the FIRST audience whose terms appear in the headline (the profile's order
    # is the priority), or nil for everyone else (peers). No headline -> nil.
    class AuthorClassifier
      def initialize(extractor: KeywordExtractor.new)
        @extractor = extractor
      end

      def call(headline:, audiences:)
        return nil if headline.to_s.strip.empty?

        audiences.find { |audience| @extractor.matches(headline, audience.terms).any? }
      end
    end
  end
end
