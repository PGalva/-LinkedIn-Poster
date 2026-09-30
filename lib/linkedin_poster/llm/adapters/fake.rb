# frozen_string_literal: true

module LinkedinPoster
  module LLM
    module Adapters
      # Adapter de mentira: testes e modo offline (LLM_PROVIDER=fake).
      #
      # - Sem `responses:` -> gera uma resposta a partir do próprio prompt,
      #   válida para QUALQUER serviço (tem "comment" e "body"). Assim a API
      #   inteira funciona sem internet e sem chave.
      # - Com `responses:` -> devolve exatamente o que o teste pediu.
      #
      # Repare: NÃO herda de Base. Em Ruby o contrato é "duck typing" — basta
      # responder a #complete e #provider_name. Herança é opcional.
      class Fake
        attr_reader :prompts

        def initialize(responses: nil, error: nil)
          @responses = responses && Array(responses).dup
          @error = error
          @prompts = []
        end

        def provider_name = "fake"

        def complete(prompt)
          @prompts << prompt
          raise @error if @error

          Response.new(text: next_response || offline_response(prompt), provider: provider_name, model: "fake", usage: nil)
        end

        private

        def next_response
          return nil if @responses.nil? || @responses.empty?

          @responses.size > 1 ? @responses.shift : @responses.first
        end

        # Resposta "realista o bastante": ecoa o começo do post ou os tópicos,
        # para você ver que o dado atravessou todas as camadas.
        def offline_response(prompt)
          post_start = prompt.user[%r{<post>\s*(.{1,80})}m, 1]&.strip&.tr("\n", " ")
          topics = prompt.user[/^Tópicos: (.+)$/, 1]

          JSON.generate(
            comment: "[offline] Comentário de exemplo sobre: \"#{post_start || 'post'}...\"",
            angle: "insight",
            body: "[offline] Post de exemplo sobre #{topics || 'seus tópicos'}.\n\nTroque LLM_PROVIDER para gerar texto de verdade.",
            hashtags: %w[offline teste]
          )
        end
      end
    end
  end
end
