# frozen_string_literal: true

module LinkedinPoster
  module Text
    # Pede-se JSON para a IA, mas IAs às vezes embrulham em ```json ... ```
    # ou escrevem uma frase antes. Este parser é tolerante na entrada e
    # rígido na saída: ou devolve um Hash com as chaves exigidas, ou levanta erro.
    class ResponseParser
      FENCED = /```(?:json)?\s*(\{.*?\})\s*```/m
      BARE = /\{.*\}/m

      def parse_json(text, required_keys: [])
        candidate = text.to_s[FENCED, 1] || text.to_s[BARE]
        raise LLM::InvalidResponseError, "the AI response contains no JSON" unless candidate

        data = JSON.parse(candidate)
        raise LLM::InvalidResponseError, "the AI returned JSON that is not an object" unless data.is_a?(Hash)

        missing = required_keys.map(&:to_s) - data.keys
        raise LLM::InvalidResponseError, "missing keys in the AI response: #{missing.join(', ')}" if missing.any?

        data
      rescue JSON::ParserError => e
        raise LLM::InvalidResponseError, "invalid JSON in the AI response: #{e.message}"
      end
    end
  end
end
