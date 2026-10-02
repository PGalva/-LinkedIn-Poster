# frozen_string_literal: true

# Composition root: the ONE place that decides which AI the app talks to
# and which profile it uses. Controllers read them from config.x.
require Rails.root.join("lib/linkedin_poster").to_s
require "yaml"

Rails.application.config.x.llm = LinkedinPoster::LLM.build # reads LLM_PROVIDER; fails at boot if a key is missing

profile_path = ENV.fetch("PROFILE_PATH", Rails.root.join("config/profile.yml").to_s)
Rails.application.config.x.profile = LinkedinPoster::Domain::UserProfile.from_h(YAML.load_file(profile_path))
