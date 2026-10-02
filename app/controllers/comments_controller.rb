# frozen_string_literal: true

# Extension -> "suggest a comment for this post"
class CommentsController < ApplicationController
  def suggest
    post = LinkedinPoster::Domain::CapturedPost.new(**post_params.to_h.symbolize_keys)
    suggestion = LinkedinPoster::Services::SuggestComment.new(llm:).call(post:, profile:)

    render json: suggestion.to_h
  end

  private

  def post_params
    params.require(:post).permit(:text, :author, :url)
  end
end
