# frozen_string_literal: true

module LinkedinPoster
  module Domain
    # O que o formulário coleta para criar um post: Objetivo, Público, Tom, Tópicos.
    PostBrief = Data.define(:goal, :audience, :tone, :topics) do
      def initialize(goal:, topics:, audience: "recruiters and people in the field", tone: nil)
        raise ValidationError, "the post goal is required" if goal.to_s.strip.empty?

        list = Array(topics).map { _1.to_s.strip }.reject(&:empty?)
        raise ValidationError, "at least one topic is required" if list.empty?

        super(goal: goal.strip, audience:, tone:, topics: list)
      end
    end
  end
end
