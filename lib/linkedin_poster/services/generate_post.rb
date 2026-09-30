# frozen_string_literal: true

module LinkedinPoster
  module Services
    # Caso de uso: "a partir do formulário, gere um post + bloco de hashtags".
    class GeneratePost
      MAX_POST_CHARS = 3_000 # limite do LinkedIn para posts

      def initialize(llm:,
                     prompt_builder: Prompts::PostPromptBuilder.new,
                     parser: Text::ResponseParser.new,
                     hashtags: Text::HashtagGenerator.new(limit: 5))
        @llm = llm
        @prompt_builder = prompt_builder
        @parser = parser
        @hashtags = hashtags
      end

      def call(brief:, profile:)
        response = @llm.complete(@prompt_builder.build(brief:, profile:))
        data = @parser.parse_json(response.text, required_keys: %w[body])

        # Prioridade: tópicos que o usuário escolheu > sugestões da IA > keywords do perfil
        tags = @hashtags.call(brief.topics, Array(data["hashtags"]), profile.keywords)
        body = fit_to_limit(strip_trailing_hashtags(data["body"]), tags)

        Domain::GeneratedPost.new(body:, hashtags: tags, provider: response.provider)
      end

      private

      # Se a IA desobedecer e puser hashtags no fim do corpo, removemos.
      def strip_trailing_hashtags(body)
        body.to_s.sub(/(\s*#[\p{L}\p{N}_]+)+\s*\z/, "").strip
      end

      def fit_to_limit(body, tags)
        room = MAX_POST_CHARS - tags.join(" ").length - 2
        body.length > room ? "#{body[0, room - 1].rstrip}…" : body
      end
    end
  end
end
