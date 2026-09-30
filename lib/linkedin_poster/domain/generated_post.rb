# frozen_string_literal: true

module LinkedinPoster
  module Domain
    # Resultado do GeneratePost: corpo + bloco de hashtags separados,
    # para a interface poder mostrar/editar cada parte.
    GeneratedPost = Data.define(:body, :hashtags, :provider) do
      def to_text
        [body, hashtags.join(" ")].reject(&:empty?).join("\n\n")
      end
    end
  end
end
