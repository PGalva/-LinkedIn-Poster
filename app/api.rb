# frozen_string_literal: true

require "sinatra/base"
require "yaml"
require_relative "../lib/linkedin_poster"

# Camada HTTP. Regra: controller MAGRO.
# Ele só: (1) lê o JSON, (2) monta objetos de domínio, (3) chama um serviço,
# (4) transforma o resultado/erro em resposta HTTP. Zero regra de negócio aqui.
#
# Se um dia migrar para Rails, só este arquivo muda — lib/ fica intacto.
class Api < Sinatra::Base
  include LinkedinPoster

  # ---- Composition root: o ÚNICO lugar que decide qual IA usar ----
  configure do
    set :show_exceptions, false
    set :raise_errors, false
    set :llm, LLM.build # lê LLM_PROVIDER do ambiente; falha no boot se faltar chave
    profile_path = ENV.fetch("PROFILE_PATH", File.expand_path("../config/profile.yml", __dir__))
    set :profile, Domain::UserProfile.from_h(YAML.load_file(profile_path))
  end

  before do
    content_type :json
    headers "Access-Control-Allow-Origin" => ENV.fetch("ALLOWED_ORIGIN", "*")
  end

  helpers do
    def payload
      @payload ||= JSON.parse(request.body.read)
    end

    def symbolize(hash, *keys)
      hash.to_h.transform_keys(&:to_sym).slice(*keys)
    end
  end

  get "/health" do
    { ok: true, provider: settings.llm.provider_name }.to_json
  end

  # Extensão -> "sugira um comentário para este post"
  post "/comments/suggest" do
    post = Domain::CapturedPost.new(**symbolize(payload.fetch("post"), :text, :author, :url))
    Services::SuggestComment.new(llm: settings.llm).call(post:, profile: settings.profile).to_h.to_json
  end

  # Formulário -> "gere um post" (Objetivo, Público, Tom, Tópicos)
  post "/posts/generate" do
    brief = Domain::PostBrief.new(**symbolize(payload.fetch("brief"), :goal, :audience, :tone, :topics))
    result = Services::GeneratePost.new(llm: settings.llm).call(brief:, profile: settings.profile)
    result.to_h.merge(full_text: result.to_text).to_json
  end

  # Extensão -> "quais destes posts do feed valem a pena?"
  post "/posts/rank" do
    posts = payload.fetch("posts").map { Domain::CapturedPost.new(**symbolize(_1, :text, :author, :url)) }
    Services::RankPosts.new.call(posts:, profile: settings.profile, limit: payload.fetch("limit", 10))
                       .map(&:to_h).to_json
  end

  # ---- Tradução de erros do domínio -> HTTP ----
  error ValidationError, KeyError, JSON::ParserError, ArgumentError do
    status 422
    { error: env["sinatra.error"].message }.to_json
  end

  error LLM::RateLimitedError do
    status 429
    { error: "a IA está limitando requisições, tente em instantes" }.to_json
  end

  error LLM::Error do
    status 502
    { error: env["sinatra.error"].message }.to_json
  end
end
