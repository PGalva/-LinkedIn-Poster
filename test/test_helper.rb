# frozen_string_literal: true

require "minitest/autorun"
require_relative "../lib/linkedin_poster"

module TestSupport
  include LinkedinPoster

  def profile
    Domain::UserProfile.from_h(
      name: "Pedro",
      headline: "UX Engineer & Designer",
      target_roles: ["UX Engineer", "Product Designer"],
      keywords: ["design system", "React", "acessibilidade", "Ruby"],
      tone: "direto e curioso"
    )
  end

  def captured_post(text = "Estamos contratando UX Engineer para cuidar do nosso design system em React.")
    Domain::CapturedPost.new(text:, author: "Ana Recrutadora", url: "https://linkedin.com/feed/update/1")
  end

  # Substitui o HttpTransport: grava o que o adapter enviaria e devolve uma
  # resposta pronta. Assim testamos o adapter inteiro sem internet.
  class FakeHttp
    attr_reader :requests

    def initialize(status: 200, body: "{}")
      @status = status
      @body = body.is_a?(String) ? body : JSON.generate(body)
      @requests = []
    end

    def post_json(url, headers:, body:)
      @requests << { url:, headers:, body: }
      LinkedinPoster::LLM::HttpTransport::RawResponse.new(status: @status, body: @body)
    end

    def last = @requests.last
  end
end
