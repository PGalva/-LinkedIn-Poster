# frozen_string_literal: true

module LinkedinPoster
  module LLM
    # Fábrica: transforma uma string de configuração ("anthropic") num adapter.
    #
    # Trocar de IA = mudar LLM_PROVIDER no .env. Adicionar uma IA nova =
    # criar um arquivo em adapters/ e uma linha aqui. Nenhum serviço muda.
    ADAPTERS = {
      "anthropic" => Adapters::Anthropic,
      "openai" => Adapters::OpenAI,
      "ollama" => Adapters::Ollama,
      "fake" => Adapters::Fake
    }.freeze

    def self.build(provider = ENV.fetch("LLM_PROVIDER", "anthropic"), **options)
      adapter_class = ADAPTERS.fetch(provider.to_s.downcase) do
        raise ConfigurationError,
              "provedor de LLM desconhecido: #{provider.inspect}. Opções: #{ADAPTERS.keys.join(', ')}"
      end
      adapter_class.new(**options)
    end
  end
end
