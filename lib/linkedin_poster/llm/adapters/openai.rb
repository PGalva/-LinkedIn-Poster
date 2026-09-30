# frozen_string_literal: true

module LinkedinPoster
  module LLM
    module Adapters
      # OpenAI Chat Completions. Como `base_url` é configurável, este mesmo
      # adapter serve para qualquer API "compatível com OpenAI" (Groq, LM Studio,
      # OpenRouter...). Um adapter, vários provedores.
      class OpenAI < Base
        def initialize(api_key: ENV["OPENAI_API_KEY"],
                       model: ENV["OPENAI_MODEL"],
                       base_url: ENV.fetch("OPENAI_BASE_URL", "https://api.openai.com/v1"),
                       http: HttpTransport.new)
          @api_key = require_config!(api_key, "OPENAI_API_KEY")
          @base_url = base_url.chomp("/")
          super(model: require_config!(model, "OPENAI_MODEL"), http:)
        end

        def provider_name = "openai"

        private

        def endpoint = "#{@base_url}/chat/completions"

        def headers = { "authorization" => "Bearer #{@api_key}" }

        def build_body(prompt)
          {
            model: @model,
            max_completion_tokens: prompt.max_tokens,
            temperature: prompt.temperature,
            messages: [
              { role: "system", content: prompt.system },
              { role: "user", content: prompt.user }
            ]
          }
        end

        def extract_text(json) = json.dig("choices", 0, "message", "content")

        def extract_usage(json) = json["usage"]
      end
    end
  end
end
