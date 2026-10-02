# frozen_string_literal: true

module LinkedinPoster
  module LLM
    module Adapters
      # A PORTA (contrato) que o resto do sistema conhece:
      #
      #   adapter.complete(prompt)  # => LLM::Response
      #   adapter.provider_name     # => "anthropic"
      #
      # e só levanta erros que herdam de LLM::Error.
      #
      # Padrão usado: Template Method. O fluxo (montar corpo -> POST -> checar
      # status -> extrair texto) é igual para todo provedor; as subclasses só
      # preenchem os "ganchos" que mudam: endpoint, headers, build_body, extract_text.
      class Base
        attr_reader :model

        def initialize(model:, http: HttpTransport.new)
          @model = model
          @http = http
        end

        def complete(prompt)
          raw = @http.post_json(endpoint, headers: headers, body: build_body(prompt))
          raise_for_status!(raw)

          json = JSON.parse(raw.body)
          text = extract_text(json).to_s
          raise InvalidResponseError, "#{provider_name} returned empty text" if text.strip.empty?

          Response.new(text:, provider: provider_name, model: @model, usage: extract_usage(json))
        rescue JSON::ParserError => e
          raise InvalidResponseError, "#{provider_name} returned invalid JSON: #{e.message}"
        end

        def provider_name
          raise NotImplementedError, "#{self.class} must define #provider_name"
        end

        private

        # ---- ganchos que cada provedor implementa ----
        def endpoint = raise(NotImplementedError)
        def headers = {}
        def build_body(_prompt) = raise(NotImplementedError)
        def extract_text(_json) = raise(NotImplementedError)
        def extract_usage(_json) = nil

        def raise_for_status!(raw)
          case raw.status
          when 200..299 then nil
          when 429 then raise RateLimitedError, "#{provider_name}: rate limit reached"
          when 500..599 then raise UnavailableError, "#{provider_name} unavailable (#{raw.status})"
          else raise RequestError, "#{provider_name} responded #{raw.status}: #{raw.body.to_s[0, 300]}"
          end
        end

        def require_config!(value, name)
          raise ConfigurationError, "#{name} is not set" if value.to_s.strip.empty?

          value
        end
      end
    end
  end
end
