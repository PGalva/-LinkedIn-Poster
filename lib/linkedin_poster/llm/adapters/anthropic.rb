# frozen_string_literal: true

module LinkedinPoster
  module LLM
    module Adapters
      # Claude via Messages API. Particularidade: o "system" vai num campo
      # próprio, fora da lista de mensagens.
      class Anthropic < Base
        URL = "https://api.anthropic.com/v1/messages"
        API_VERSION = "2023-06-01"

        def initialize(api_key: ENV["ANTHROPIC_API_KEY"],
                       model: ENV.fetch("ANTHROPIC_MODEL", "claude-sonnet-5"),
                       http: HttpTransport.new)
          @api_key = require_config!(api_key, "ANTHROPIC_API_KEY")
          super(model:, http:)
        end

        def provider_name = "anthropic"

        private

        def endpoint = URL

        def headers
          { "x-api-key" => @api_key, "anthropic-version" => API_VERSION }
        end

        def build_body(prompt)
          {
            model: @model,
            max_tokens: prompt.max_tokens,
            temperature: prompt.temperature,
            system: prompt.system,
            messages: [{ role: "user", content: prompt.user }]
          }
        end

        def extract_text(json)
          json.fetch("content", []).select { _1["type"] == "text" }.map { _1["text"] }.join
        end

        def extract_usage(json) = json["usage"]
      end
    end
  end
end
