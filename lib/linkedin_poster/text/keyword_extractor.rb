# frozen_string_literal: true

module LinkedinPoster
  module Text
    # Extrai palavras-chave e verifica quais termos do usuário aparecem num texto.
    #
    # Lição de sênior: nem tudo precisa de IA. Isto é determinístico, grátis,
    # instantâneo e testável. Use o LLM só onde ele agrega (texto criativo).
    class KeywordExtractor
      STOPWORDS = Set.new(%w[
        a o e de da do das dos em no na nos nas um uma uns umas para por com sem
        que se mais mas como ao aos as os ou ja nao sim muito muita isso esse essa
        este esta ser ter foi sao era voce eu nos eles elas meu minha seu sua sobre
        the and for with that this from are was were you your our have has will
        not but can all about into just more what when how who why its it's
      ]).freeze

      def initialize(min_length: 3, stopwords: STOPWORDS)
        @min_length = min_length
        @stopwords = stopwords
      end

      # Palavras mais frequentes do texto.
      def call(text, limit: 10)
        tokens(text)
          .tally
          .sort_by { |word, count| [-count, word] }
          .first(limit)
          .map(&:first)
      end

      # Quais dos `terms` aparecem no texto (aceita termos com várias palavras,
      # ex.: "design system"). Ignora acentos e maiúsculas.
      def matches(text, terms)
        folded = Normalizer.fold(text)
        terms.select do |term|
          needle = Regexp.escape(Normalizer.fold(term).strip)
          !needle.empty? && folded.match?(/(?<![a-z0-9])#{needle}(?![a-z0-9])/)
        end
      end

      def tokens(text)
        Normalizer.fold(text)
                  .scan(/[a-z0-9][a-z0-9+#.\-]*/)
                  .map { _1.sub(/[.\-]+\z/, "") }
                  .reject { _1.length < @min_length || @stopwords.include?(_1) }
      end
    end
  end
end
