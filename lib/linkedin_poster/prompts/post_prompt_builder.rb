# frozen_string_literal: true

module LinkedinPoster
  module Prompts
    # Monta o prompt do "Criador de Posts" a partir do formulário
    # (Objetivo, Público, Tom, Tópicos) + perfil do usuário.
    class PostPromptBuilder
      def build(brief:, profile:)
        Domain::Prompt.new(
          system: system_prompt(profile),
          user: user_prompt(brief, profile),
          max_tokens: 1_200,
          temperature: 0.8
        )
      end

      private

      def system_prompt(profile)
        <<~PROMPT
          Você é redator(a) de LinkedIn para #{profile.name} (#{profile.headline}).

          Regras do post:
          - Idioma: #{profile.language}.
          - Primeira linha é um gancho forte (sem clickbait).
          - Parágrafos curtos (1 a 3 linhas), entre 600 e 1300 caracteres no total.
          - Termine com uma chamada para ação coerente com o objetivo.
          - Não invente números, empresas ou experiências.
          - NÃO coloque hashtags no corpo; sugira-as à parte.

          Responda APENAS com JSON no formato:
          {"body": "texto do post", "hashtags": ["termo1", "termo2", "termo3"]}
        PROMPT
      end

      def user_prompt(brief, profile)
        <<~PROMPT
          Objetivo do post: #{brief.goal}
          Público-alvo: #{brief.audience}
          Tom: #{brief.tone || profile.tone}
          Tópicos: #{brief.topics.join(', ')}
          Cargos que o autor busca: #{profile.target_roles.join(', ')}
        PROMPT
      end
    end
  end
end
