# frozen_string_literal: true

require_relative "boot"

# Only the pieces of Rails we use: routing + controllers.
# ActiveRecord comes in Phase 5, when we start storing history.
require "rails"
require "action_controller/railtie"

Bundler.require(*Rails.groups)

module LinkedinPosterApp
  class Application < Rails::Application
    config.load_defaults 8.0
    config.api_only = true

    # lib/linkedin_poster is NOT autoloaded on purpose: the core is plain Ruby
    # and is loaded once by config/initializers/linkedin_poster.rb.
    # (Its folder names like llm/ would also clash with Zeitwerk's naming: LLM vs Llm.)
  end
end
