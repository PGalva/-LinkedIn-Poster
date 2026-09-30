# frozen_string_literal: true

module LinkedinPoster
  module Domain
    # Um prompt NEUTRO de provedor. O PromptBuilder cria isto; cada adapter
    # traduz para o formato do seu provedor (Claude usa "system" separado,
    # OpenAI/Ollama usam uma mensagem com role "system", etc.).
    #
    # É este objeto que permite trocar de IA sem tocar nos serviços.
    Prompt = Data.define(:system, :user, :max_tokens, :temperature) do
      def initialize(system:, user:, max_tokens: 800, temperature: 0.7)
        super
      end
    end
  end
end
