# frozen_string_literal: true

module LinkedinPoster
  module Domain
    # A kind of job the user wants to apply for, plus the words recruiters use for it.
    #
    #   JobTarget.new(name: "UI/UX Design", terms: ["ux designer", "ui designer", "product designer"])
    #
    # Recruiters rarely write the exact title you have in mind, so matching uses
    # every term (the name itself is always one of them).
    JobTarget = Data.define(:name, :terms) do
      def initialize(name:, terms: [])
        clean_name = name.to_s.strip
        raise ValidationError, "job target needs a name" if clean_name.empty?

        all_terms = ([clean_name] + Array(terms)).map { _1.to_s.strip }.reject(&:empty?).uniq
        super(name: clean_name, terms: all_terms)
      end

      def self.from_h(hash)
        h = hash.transform_keys(&:to_sym)
        new(name: h.fetch(:name), terms: Array(h[:terms]))
      end
    end
  end
end
