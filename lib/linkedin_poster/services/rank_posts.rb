# frozen_string_literal: true

module LinkedinPoster
  module Services
    # Caso de uso: "quais posts do feed valem meu comentário?"
    #
    # Sem IA: pontua por aderência aos cargos e keywords do perfil.
    # Barato o bastante para rodar em TODO post que aparece no feed;
    # a IA só é chamada depois, nos posts que o usuário escolher.
    class RankPosts
      ROLE_WEIGHT = 3
      KEYWORD_WEIGHT = 1

      def initialize(extractor: Text::KeywordExtractor.new)
        @extractor = extractor
      end

      def call(posts:, profile:, limit: 10)
        posts
          .map { rank(_1, profile) }
          .select { _1.score.positive? }
          .sort_by { -_1.score }
          .first(limit)
      end

      private

      def rank(post, profile)
        roles = @extractor.matches(post.text, profile.target_roles)
        keywords = @extractor.matches(post.text, profile.keywords)
        score = (roles.size * ROLE_WEIGHT) + (keywords.size * KEYWORD_WEIGHT)

        Domain::RankedPost.new(post:, score:, matched_keywords: roles + keywords)
      end
    end
  end
end
