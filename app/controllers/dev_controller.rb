# frozen_string_literal: true

# Development-only playground: serves extension/dev/feed.html and the extension's
# content script, so the real content.js can be tried on fake posts at
# http://localhost:9292/dev/feed — no LinkedIn, no Chrome extension install.
#
# Routes exist only in development (config/routes.rb). Files are whitelisted:
# never build a file path straight from a URL (path traversal).
class DevController < ApplicationController
  EXTENSION_FILES = {
    "selectors.js" => "text/javascript",
    "content.js" => "text/javascript",
    "content.css" => "text/css"
  }.freeze

  def feed
    send_file Rails.root.join("extension/dev/feed.html"), type: "text/html", disposition: "inline"
  end

  def extension_file
    name = params[:file].to_s
    type = EXTENSION_FILES[name]
    return head(:not_found) unless type

    send_file Rails.root.join("extension", name), type:, disposition: "inline"
  end
end
