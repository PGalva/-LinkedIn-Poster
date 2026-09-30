# frozen_string_literal: true

module LinkedinPoster
  module LLM
    # O que TODO adapter devolve, independentemente do provedor.
    Response = Data.define(:text, :provider, :model, :usage)
  end
end
