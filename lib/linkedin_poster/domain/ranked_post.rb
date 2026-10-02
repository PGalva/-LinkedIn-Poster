# frozen_string_literal: true

module LinkedinPoster
  module Domain
    # A feed post scored by how close it is to the jobs the user wants.
    #   job_opening:      the post looks like a hiring post for one of the targets
    #   matched_targets:  which job targets it mentions ("UI/UX Design", "Co-op")
    #   matched_keywords: profile keywords it mentions ("React", "Figma")
    RankedPost = Data.define(:post, :score, :job_opening, :matched_targets, :matched_keywords) do
      # Human-readable "why is this post here?", shown in the extension.
      def reason
        parts = []
        parts << "Job opening" if job_opening
        parts << matched_targets.join(", ") if matched_targets.any?
        parts << "keywords: #{matched_keywords.join(', ')}" if matched_keywords.any?
        parts.join(" · ")
      end

      def to_h
        { post: post.to_h, score:, job_opening:, matched_targets:, matched_keywords:, reason: }
      end
    end
  end
end
