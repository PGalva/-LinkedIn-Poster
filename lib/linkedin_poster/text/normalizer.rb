# frozen_string_literal: true

module LinkedinPoster
  module Text
    # Funções puras de normalização. "Puras" = mesma entrada, mesma saída,
    # sem efeito colateral. As mais fáceis de testar do projeto inteiro.
    module Normalizer
      module_function

      def strip_accents(text)
        text.to_s.unicode_normalize(:nfkd).gsub(/\p{Mn}/, "")
      end

      # "Programação em Ruby" -> "programacao em ruby"
      def fold(text)
        strip_accents(text).downcase
      end
    end
  end
end
