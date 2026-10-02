# frozen_string_literal: true

class HealthController < ApplicationController
  def show
    render json: { ok: true, provider: llm.provider_name }
  end
end
