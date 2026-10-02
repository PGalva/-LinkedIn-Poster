# frozen_string_literal: true

require "net/http"
require "uri"

module LinkedinPoster
  module LLM
    # O ÚNICO lugar do projeto que abre conexão HTTP com uma IA.
    #
    # Os adapters recebem uma instância disto por injeção de dependência
    # (`http:` no construtor). Nos testes passamos um objeto falso com o mesmo
    # método #post_json — e testamos o adapter inteiro sem internet.
    class HttpTransport
      RawResponse = Data.define(:status, :body)

      NETWORK_ERRORS = [
        Net::OpenTimeout, Net::ReadTimeout, SocketError,
        Errno::ECONNREFUSED, Errno::ECONNRESET, Errno::EHOSTUNREACH
      ].freeze

      def initialize(open_timeout: 5, read_timeout: 60)
        @open_timeout = open_timeout
        @read_timeout = read_timeout
      end

      def post_json(url, headers:, body:)
        uri = URI(url)
        http = Net::HTTP.new(uri.host, uri.port)
        http.use_ssl = uri.scheme == "https"
        http.open_timeout = @open_timeout
        http.read_timeout = @read_timeout

        request = Net::HTTP::Post.new(uri, { "content-type" => "application/json" }.merge(headers))
        request.body = JSON.generate(body)

        response = http.request(request)
        RawResponse.new(status: response.code.to_i, body: response.body.to_s)
      rescue *NETWORK_ERRORS => e
        raise UnavailableError, "network error calling #{uri.host}: #{e.class}"
      end
    end
  end
end
