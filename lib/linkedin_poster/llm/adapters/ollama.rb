# frozen_string_literal: true

module LinkedinPoster
  module LLM
    module Adapters
      # Local model via Ollama (free, no key). Great for development without
      # spending credits — and proof that the port works with any AI.
      #
      # OLLAMA_URL depends on where Ollama runs:
      #   - Compose service (--profile ollama): http://ollama:11434
      #   - Installed on your machine, API in Docker: http://host.docker.internal:11434
      #   - Both on your machine, no Docker: http://localhost:11434
      #
      # On CPU a post can take minutes. OLLAMA_TIMEOUT (seconds, default 300) is how long
      # we wait; OLLAMA_KEEP_ALIVE (default 30m) keeps the model loaded between requests.
      class Ollama < Base
        def initialize(model: ENV.fetch("OLLAMA_MODEL", "llama3.1"),
                       base_url: ENV.fetch("OLLAMA_URL", "http://localhost:11434"),
                       http: HttpTransport.new(read_timeout: Integer(ENV.fetch("OLLAMA_TIMEOUT", "300"))),
                       keep_alive: ENV.fetch("OLLAMA_KEEP_ALIVE", "30m"))
          @keep_alive = keep_alive
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
            # Small local models often wrap JSON in prose; this forces valid JSON.
            format: "json",
            # Keep the model in memory between requests: loading it is the slowest part on CPU.
            keep_alive: @keep_alive,
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
