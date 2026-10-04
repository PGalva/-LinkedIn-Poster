# frozen_string_literal: true

module LinkedinPoster
  module Domain
    # What the Post Creator form collects.
    #
    # - idea:  what you want to say, in your own words (the main input since v0.6)
    # - goal:  why you are posting (get noticed by recruiters, share a lesson...)
    # - topics, audience, tone: optional refinements
    #
    # Rule: we need at least an idea OR a goal — otherwise the AI has nothing to write about.
    PostBrief = Data.define(:idea, :goal, :audience, :tone, :topics) do
      def initialize(idea: nil, goal: nil, topics: [], audience: nil, tone: nil)
        idea = idea.to_s.strip
        goal = goal.to_s.strip
        raise ValidationError, "tell me what you want to say (idea) or the post's goal" if idea.empty? && goal.empty?

        list = Array(topics).map { _1.to_s.strip }.reject(&:empty?)
        audience = audience.to_s.strip.empty? ? "recruiters and people in the field" : audience.strip
        tone = tone.to_s.strip.empty? ? nil : tone.strip

        super(idea: idea.empty? ? nil : idea, goal: goal.empty? ? nil : goal, audience:, tone:, topics: list)
      end
    end
  end
end
