# frozen_string_literal: true

module LinkedinPoster
  module LLM
    module Adapters
      # Modelo local via Ollama (sem custo, sem chave). Ótimo para desenvolver
      # sem gastar créditos — e prova de que a porta funciona com qualquer IA.
      class Ollama < Base
        def initialize(model: ENV.fetch("OLLAMA_MODEL", "llama3.1"),
                       base_url: ENV.fetch("OLLAMA_URL", "http://localhost:11434"),
                       http: HttpTransport.new(read_timeout: 180))
          @base_url = base_url.chomp("/")
          super(model:, http:)
        end

        def provider_name = "ollama"

        private

        def endpoint = "#{@base_url}/api/chat"

        def build_body(prompt)
          {
            model: @model,
            stream: false,
            options: { temperature: prompt.temperature, num_predict: prompt.max_tokens },
            messages: [
              { role: "system", content: prompt.system },
              { role: "user", content: prompt.user }
            ]
          }
        end

        def extract_text(json) = json.dig("message", "content")
      end
    end
  end
end
