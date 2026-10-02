# frozen_string_literal: true

# Thin controllers. Each action only:
#   1. reads params, 2. builds domain objects, 3. calls ONE service,
#   4. renders the result.
# Business rules live in lib/linkedin_poster, never here.
class ApplicationController < ActionController::API
  # Translate core errors into HTTP. rescue_from checks the LAST declared
  # handler first, so the generic LLM::Error goes before its subclass.
  rescue_from LinkedinPoster::LLM::Error do |error|
    render_error(error.message, 502)
  end

  rescue_from LinkedinPoster::LLM::RateLimitedError do
    render_error("the AI provider is rate limiting us, try again in a moment", 429)
  end

  rescue_from LinkedinPoster::ValidationError, ActionController::ParameterMissing, ArgumentError do |error|
    render_error(error.message, 422)
  end

  private

  def llm = Rails.configuration.x.llm
  def profile = Rails.configuration.x.profile

  def render_error(message, status)
    render json: { error: message }, status:
  end
end
