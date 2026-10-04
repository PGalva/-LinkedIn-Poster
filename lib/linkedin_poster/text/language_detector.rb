# frozen_string_literal: true

module LinkedinPoster
  module Text
    # Guesses the language of a text by counting very common words ("the", "and"
    # vs "de", "que"). No AI, no gem: cheap, predictable and easy to test.
    #
    # Returns nil when it is not confident (too short, or a tie) so the caller
    # can fall back to something else, e.g. the profile's language.
    #
    # Why isn't this inside CapturedPost? The domain only holds data and its
    # validation; *interpreting* text is a rule that lives in text/, next to the
    # keyword and hashtag rules. Services combine both.
    class LanguageDetector
      STOPWORDS = {
        "en" => Set.new(%w[the and to of in is for on with you we are this that our it be as at
                           your have will an or from they their i my me us can about what how]),
        "pt" => Set.new(%w[de que e o do da em um uma para com não os as no na por mais se dos das
                           ao é você nós estamos são seu sua vaga meu minha nosso nossa como sobre])
      }.freeze

      NAMES = { "en" => "English", "pt" => "Portuguese" }.freeze

      # "en", "pt" or nil
      def call(text)
        words = text.to_s.downcase.scan(/\p{L}+/)
        scores = STOPWORDS.transform_values { |set| words.count { set.include?(_1) } }
        best, best_score = scores.max_by { _2 }
        runner_up = scores.except(best).values.max || 0

        best_score.positive? && best_score > runner_up ? best : nil
      end

      # "English", "Portuguese" or nil — the form the prompt uses
      def language_name(text) = NAMES[call(text)]
    end
  end
end
