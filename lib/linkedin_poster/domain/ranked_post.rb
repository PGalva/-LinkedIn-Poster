# frozen_string_literal: true

module LinkedinPoster
  module Domain
    # A feed post scored by how much it helps you get seen by people who can hire you.
    #   job_opening:       the post looks like a hiring post for one of the targets
    #   matched_targets:   which job targets it mentions ("UI/UX Design", "Co-op")
    #   matched_keywords:  profile keywords it mentions ("React", "Figma")
    #   author_type/label: who wrote it ("recruiter" / "Recruiter"), nil for peers or unknown
    #   matched_locations: your locations it mentions ("Vancouver")
    #   matched_companies: your target companies it mentions, in the text, author or headline
    RankedPost = Data.define(:post, :score, :job_opening, :matched_targets, :matched_keywords,
                             :author_type, :author_label, :matched_locations, :matched_companies) do
      def initialize(post:, score:, job_opening:, matched_targets:, matched_keywords:,
                     author_type: nil, author_label: nil, matched_locations: [], matched_companies: [])
        super
      end

      # Human-readable "why is this post here?", shown in the extension.
      # Who first (that's the north star), then where, then what.
      def reason
        parts = []
        parts << author_label if author_label
        parts << "Job opening" if job_opening
        parts << matched_companies.join(", ") if matched_companies.any?
        parts << matched_locations.join(", ") if matched_locations.any?
        parts << matched_targets.join(", ") if matched_targets.any?
        parts << "keywords: #{matched_keywords.join(', ')}" if matched_keywords.any?
        parts.join(" · ")
      end

      def to_h
        { post: post.to_h, score:, job_opening:, matched_targets:, matched_keywords:,
          author_type:, author_label:, matched_locations:, matched_companies:, reason: }
      end
    end
  end
end
