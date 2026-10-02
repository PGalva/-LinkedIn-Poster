# frozen_string_literal: true

require "json"
require "set"

# Núcleo do LinkedIn Poster.
#
# Regra de ouro da arquitetura: NADA aqui dentro conhece Sinatra, Rails,
# a extensão do Chrome ou um provedor de IA específico. O núcleo só conhece
# a *porta* LLM (qualquer objeto que responda a #complete(prompt)).
module LinkedinPoster
  class Error < StandardError; end
  class ValidationError < Error; end
end

# A ordem importa: domínio -> LLM -> utilitários de texto -> prompts -> serviços.
# (Em Rails o Zeitwerk faria isso sozinho; aqui deixamos explícito para você ver
#  quem depende de quem.)
%w[
  domain/job_target
  domain/user_profile
  domain/captured_post
  domain/post_brief
  domain/prompt
  domain/comment_suggestion
  domain/generated_post
  domain/ranked_post

  llm/errors
  llm/response
  llm/http_transport
  llm/adapters/base
  llm/adapters/anthropic
  llm/adapters/openai
  llm/adapters/ollama
  llm/adapters/fake
  llm/registry

  text/normalizer
  text/keyword_extractor
  text/hashtag_generator
  text/response_parser

  prompts/comment_prompt_builder
  prompts/post_prompt_builder

  services/suggest_comment
  services/generate_post
  services/rank_posts
].each { |file| require_relative "linkedin_poster/#{file}" }
