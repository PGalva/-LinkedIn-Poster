# frozen_string_literal: true

module LinkedinPoster
  module Domain
    # Resultado do SuggestComment. "angle" = qual abordagem o comentário usou
    # (ex.: "pergunta", "experiência própria") — útil para a UI e para métricas.
    CommentSuggestion = Data.define(:text, :angle, :provider)
  end
end
