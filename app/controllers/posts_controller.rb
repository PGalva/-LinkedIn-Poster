# frozen_string_literal: true

class PostsController < ApplicationController
  # Extension popup -> "write a post" (idea, goal, audience, tone, topics)
  def generate
    brief = LinkedinPoster::Domain::PostBrief.new(**brief_params.to_h.symbolize_keys)
    post = LinkedinPoster::Services::GeneratePost.new(llm:).call(brief:, profile:)

    render json: post.to_h.merge(full_text: post.to_text)
  end

  # Extension popup -> "re-check my edited post" (rules only, no AI: instant and free)
  def check
    body = params.require(:body)
    hashtags = Array(params[:hashtags]).map(&:to_s)
    checks = LinkedinPoster::Text::EngagementCheck.new.call(body:, hashtags:)

    render json: checks.map(&:to_h)
  end

  # Extension -> "which of these feed posts are about the jobs I want?"
  def rank
    posts = params.require(:posts).map do |raw|
      LinkedinPoster::Domain::CapturedPost.new(**raw.permit(:text, :author, :author_headline, :url).to_h.symbolize_keys)
    end
    limit = params.fetch(:limit, 10).to_i
    ranked = LinkedinPoster::Services::RankPosts.new.call(posts:, profile:, limit:)

    render json: ranked.map(&:to_h)
  end

  private

  def brief_params
    params.require(:brief).permit(:idea, :goal, :audience, :tone, topics: [])
  end
end
