# frozen_string_literal: true

module LinkedinPoster
  module LLM
    # Hierarquia de erros PRÓPRIA. Cada adapter traduz o erro do provedor
    # (HTTP 429 da Anthropic, timeout do Ollama...) para um destes.
    # Resultado: o serviço/controller nunca faz `rescue Anthropic::Qualquercoisa`.
    class Error < LinkedinPoster::Error; end
    class ConfigurationError < Error; end   # falta API key, provedor inválido
    class RateLimitedError < Error; end     # 429
    class UnavailableError < Error; end     # 5xx, timeout, rede
    class RequestError < Error; end         # outros 4xx (prompt inválido, modelo errado)
    class InvalidResponseError < Error; end # a IA respondeu algo que não conseguimos usar
  end
end
