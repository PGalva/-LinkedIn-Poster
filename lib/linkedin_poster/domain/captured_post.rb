# frozen_string_literal: true

module LinkedinPoster
  module Domain
    # A post the extension captured from the LinkedIn screen.
    # Validation lives HERE (in the domain), not in the controller: every entry
    # point (API, CLI, tests) gets the same rule for free.
    #
    # author_headline: the line under the author's name ("Design Manager at Acme"),
    #   used to tell recruiters and hiring managers from peers. Optional.
    CapturedPost = Data.define(:text, :author, :author_headline, :url) do
      def initialize(text:, author: nil, author_headline: nil, url: nil)
        clean = text.to_s.strip
        raise ValidationError, "the post text is empty" if clean.empty?

        headline = author_headline.to_s.strip[0, 300]
        super(text: clean, author: author&.strip, author_headline: headline.empty? ? nil : headline, url:)
      end
    end
  end
end
