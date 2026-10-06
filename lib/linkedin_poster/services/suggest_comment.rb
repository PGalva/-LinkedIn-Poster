# frozen_string_literal: true

module LinkedinPoster
  module Services
    # Caso de uso: "dado um post capturado, sugira um comentário".
    #
    # Repare nas dependências no construtor (injeção de dependência):
    #   - llm: QUALQUER objeto com #complete. O serviço não sabe se é Claude.
    #   - prompt_builder / parser: têm padrão, mas podem ser trocados em teste.
    #
    # Um serviço = um verbo = um método público (#call).
    class SuggestComment
      MAX_COMMENT_CHARS = 1_250 # limite do LinkedIn para comentários

      def initialize(llm:,
                     prompt_builder: Prompts::CommentPromptBuilder.new,
                     parser: Text::ResponseParser.new,
                     language_detector: Text::LanguageDetector.new,
                     classifier: Text::AuthorClassifier.new)
        @llm = llm
        @classifier = classifier
        @prompt_builder = prompt_builder
        @parser = parser
        @language_detector = language_detector
      end

      def call(post:, profile:)
        # Reply in the post's language; fall back to the profile's when unsure.
        language = @language_detector.language_name(post.text) || profile.language
        # Who wrote it decides the approach (recruiter, hiring manager, field reference, peer).
        audience = @classifier.call(headline: post.author_headline, audiences: profile.audiences)
        prompt = @prompt_builder.build(post:, profile:, language:, audience:)
        response = @llm.complete(prompt)
        data = @parser.parse_json(response.text, required_keys: %w[comment])

        Domain::CommentSuggestion.new(
          text: sanitize(data["comment"]),
          angle: data["angle"],
          provider: response.provider
        )
      end

      private

      # A IA foi instruída, mas a regra de negócio é garantida em código.
      def sanitize(text)
        clean = text.to_s
                    .gsub(/(^|\s)#[\p{L}\p{N}_]+/, "\\1") # remove hashtags
                    .gsub(/[ \t]{2,}/, " ")
                    .strip[0, MAX_COMMENT_CHARS]
        raise LLM::InvalidResponseError, "the AI returned an empty comment" if clean.empty?

        clean
      end
    end
  end
end
