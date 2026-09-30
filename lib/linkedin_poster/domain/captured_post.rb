# frozen_string_literal: true

module LinkedinPoster
  module Domain
    # Um post que a extensão capturou na tela do LinkedIn.
    # A validação mora AQUI (no domínio), não no controller: assim qualquer
    # porta de entrada (API, CLI, teste) recebe a mesma regra de graça.
    CapturedPost = Data.define(:text, :author, :url) do
      def initialize(text:, author: nil, url: nil)
        clean = text.to_s.strip
        raise ValidationError, "o texto do post está vazio" if clean.empty?

        super(text: clean, author: author&.strip, url: url)
      end
    end
  end
end
