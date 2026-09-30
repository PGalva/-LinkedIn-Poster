# frozen_string_literal: true

module LinkedinPoster
  module Text
    # Gera as # corretas a partir de qualquer lista de candidatos
    # (tópicos do usuário, sugestões da IA, palavras-chave...).
    #
    # Regras de negócio que NÃO deixamos na mão da IA:
    #  - formato CamelCase sem acento/espaço ("design system" -> #DesignSystem)
    #  - preserva siglas ("UX", "iOS")
    #  - sem duplicatas (ignora maiúsculas/acentos)
    #  - no máximo `limit` hashtags (3 a 5 funciona melhor no LinkedIn)
    #  - a ordem dos argumentos é a prioridade
    class HashtagGenerator
      def initialize(limit: 5)
        @limit = limit
      end

      def call(*candidate_lists)
        candidate_lists
          .flatten
          .compact
          .filter_map { to_hashtag(_1) }
          .uniq { Normalizer.fold(_1) }
          .first(@limit)
      end

      def to_hashtag(raw)
        words = Normalizer.strip_accents(raw.to_s.strip.delete_prefix("#"))
                          .split(/[^A-Za-z0-9]+/)
                          .reject(&:empty?)
        return nil if words.empty?

        tag = words.map { |w| w.match?(/[A-Z]/) ? w : w.capitalize }.join
        return nil if tag.length < 2 || tag.length > 40 || tag.match?(/\A\d+\z/)

        "##{tag}"
      end
    end
  end
end
