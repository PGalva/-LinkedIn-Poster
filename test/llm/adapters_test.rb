# frozen_string_literal: true

require_relative "../test_helper"

# TESTE DE CONTRATO: todo adapter novo precisa passar por aqui.
# É isto que garante que "trocar de IA não quebra o sistema".
module LLMContract
  def test_contract_complete_returns_response_with_text
    response = adapter(http: TestSupport::FakeHttp.new(body: success_body)).complete(sample_prompt)

    assert_kind_of LinkedinPoster::LLM::Response, response
    assert_equal "olá", response.text
    assert_equal adapter(http: TestSupport::FakeHttp.new).provider_name, response.provider
  end

  def test_contract_429_becomes_rate_limited_error
    assert_raises(LinkedinPoster::LLM::RateLimitedError) do
      adapter(http: TestSupport::FakeHttp.new(status: 429)).complete(sample_prompt)
    end
  end

  def test_contract_5xx_becomes_unavailable_error
    assert_raises(LinkedinPoster::LLM::UnavailableError) do
      adapter(http: TestSupport::FakeHttp.new(status: 503)).complete(sample_prompt)
    end
  end

  def test_contract_4xx_becomes_request_error
    assert_raises(LinkedinPoster::LLM::RequestError) do
      adapter(http: TestSupport::FakeHttp.new(status: 400, body: { error: "bad" })).complete(sample_prompt)
    end
  end

  def test_contract_garbage_body_becomes_invalid_response_error
    assert_raises(LinkedinPoster::LLM::InvalidResponseError) do
      adapter(http: TestSupport::FakeHttp.new(body: "<html>oops</html>")).complete(sample_prompt)
    end
  end

  def sample_prompt
    LinkedinPoster::Domain::Prompt.new(system: "seja breve", user: "diga olá", max_tokens: 50)
  end
end

class AnthropicAdapterTest < Minitest::Test
  include TestSupport
  include LLMContract

  def adapter(http:) = LLM::Adapters::Anthropic.new(api_key: "sk-test", model: "claude-test", http:)
  def success_body = { content: [{ type: "text", text: "olá" }], usage: { input_tokens: 3 } }

  def test_sends_system_outside_messages_and_auth_headers
    http = FakeHttp.new(body: success_body)
    adapter(http:).complete(sample_prompt)

    assert_equal "https://api.anthropic.com/v1/messages", http.last[:url]
    assert_equal "sk-test", http.last[:headers]["x-api-key"]
    assert_equal "seja breve", http.last[:body][:system]
    assert_equal [{ role: "user", content: "diga olá" }], http.last[:body][:messages]
    assert_equal 50, http.last[:body][:max_tokens]
  end

  def test_missing_api_key_fails_fast
    assert_raises(LLM::ConfigurationError) { LLM::Adapters::Anthropic.new(api_key: "", http: TestSupport::FakeHttp.new) }
  end
end

class OpenAIAdapterTest < Minitest::Test
  include TestSupport
  include LLMContract

  def adapter(http:) = LLM::Adapters::OpenAI.new(api_key: "sk-test", model: "gpt-test", base_url: "https://api.openai.com/v1", http:)
  def success_body = { choices: [{ message: { content: "olá" } }] }

  def test_sends_system_as_first_message
    http = FakeHttp.new(body: success_body)
    adapter(http:).complete(sample_prompt)

    assert_equal "https://api.openai.com/v1/chat/completions", http.last[:url]
    assert_equal "Bearer sk-test", http.last[:headers]["authorization"]
    assert_equal "system", http.last[:body][:messages].first[:role]
  end

  def test_base_url_allows_openai_compatible_providers
    http = FakeHttp.new(body: success_body)
    LLM::Adapters::OpenAI.new(api_key: "k", model: "m", base_url: "https://api.groq.com/openai/v1/", http:)
                         .complete(sample_prompt)

    assert_equal "https://api.groq.com/openai/v1/chat/completions", http.last[:url]
  end
end

class OllamaAdapterTest < Minitest::Test
  include TestSupport
  include LLMContract

  def adapter(http:) = LLM::Adapters::Ollama.new(model: "llama-test", base_url: "http://localhost:11434", http:)
  def success_body = { message: { role: "assistant", content: "olá" } }

  def test_disables_streaming
    http = FakeHttp.new(body: success_body)
    adapter(http:).complete(sample_prompt)

    assert_equal false, http.last[:body][:stream]
    assert_equal "http://localhost:11434/api/chat", http.last[:url]
  end

  def test_asks_for_json_output
    http = FakeHttp.new(body: success_body)
    adapter(http:).complete(sample_prompt)

    assert_equal "json", http.last[:body][:format]
  end
end

class RegistryTest < Minitest::Test
  include TestSupport

  def test_builds_adapter_by_name
    assert_instance_of LLM::Adapters::Fake, LLM.build("fake")
    assert_instance_of LLM::Adapters::Ollama, LLM.build("OLLAMA", http: TestSupport::FakeHttp.new)
  end

  def test_unknown_provider_lists_options
    error = assert_raises(LLM::ConfigurationError) { LLM.build("gemini") }
    assert_match(/anthropic, openai, ollama, fake/, error.message)
  end
end
