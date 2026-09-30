# frozen_string_literal: true

module LinkedinPoster
  module Domain
    # Um post do feed com a nota de relevância para os objetivos do usuário.
    RankedPost = Data.define(:post, :score, :matched_keywords) do
      def to_h
        { post: post.to_h, score:, matched_keywords: }
      end
    end
  end
end
