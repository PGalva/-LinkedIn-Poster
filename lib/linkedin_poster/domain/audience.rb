# frozen_string_literal: true

module LinkedinPoster
  module Domain
    # A kind of post AUTHOR you want to be seen by, plus the words their headlines use.
    #
    #   Audience.new(type: "recruiter", label: "Recruiter", terms: ["talent acquisition", "recruiter"])
    #
    # Same idea as JobTarget, but for WHO wrote the post instead of WHAT it says.
    # Order matters: the first audience whose terms match the headline wins, so list
    # the most valuable ones first (a "Recruiter & UX Lead" counts as a recruiter).
    Audience = Data.define(:type, :label, :terms) do
      def initialize(type:, label: nil, terms: [])
        clean_type = type.to_s.strip
        raise ValidationError, "audience needs a type" if clean_type.empty?

        clean_terms = Array(terms).map { _1.to_s.strip }.reject(&:empty?).uniq
        super(type: clean_type, label: (label || clean_type.tr("_", " ").capitalize).to_s, terms: clean_terms)
      end

      def self.from_h(hash)
        h = hash.transform_keys(&:to_sym)
        new(type: h.fetch(:type), label: h[:label], terms: Array(h[:terms]))
      end
    end

    # Constants go in a reopened class: inside the Data.define block they would land in Domain.
    class Audience
      # Used when profile.yml has no `audiences:` list. Terms in English and Portuguese.
      DEFAULTS = [
        {
          type: "recruiter", label: "Recruiter",
          terms: ["recruiter", "recruiting", "talent acquisition", "talent partner", "technical recruiter",
                  "sourcer", "headhunter", "people partner", "hr business partner",
                  "recrutador", "recrutadora", "recrutamento", "aquisicao de talentos", "tech recruiter"]
        },
        {
          type: "hiring_manager", label: "Hiring manager",
          terms: ["head of design", "design manager", "design director", "director of design",
                  "ux manager", "ux director", "vp of design", "engineering manager", "head of engineering",
                  "director of engineering", "vp of engineering", "cto", "founder", "co-founder",
                  "gerente de design", "gerente de engenharia", "head de design", "diretor de design"]
        },
        {
          type: "bubble", label: "Field reference",
          terms: ["senior product designer", "staff designer", "principal designer", "lead designer",
                  "ux lead", "design lead", "product design lead", "senior ux designer",
                  "staff engineer", "principal engineer", "tech lead", "developer advocate"]
        }
      ].freeze

      def self.defaults = DEFAULTS.map { new(**_1) }
    end
  end
end
