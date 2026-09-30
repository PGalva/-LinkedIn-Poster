# frozen_string_literal: true

module LinkedinPoster
  module Domain
    # Quem é o usuário e o que ele está buscando no mercado.
    # Por enquanto vem de config/profile.yml; mais tarde pode vir de um banco.
    #
    # Por que Data.define? Value objects imutáveis: depois de criado, ninguém
    # altera o perfil "sem querer" no meio de um serviço.
    UserProfile = Data.define(:name, :headline, :target_roles, :keywords, :tone, :language) do
      def self.from_h(hash)
        h = hash.transform_keys(&:to_sym)
        new(
          name: h.fetch(:name),
          headline: h.fetch(:headline, ""),
          target_roles: Array(h[:target_roles]),
          keywords: Array(h[:keywords]),
          tone: h.fetch(:tone, "profissional e próximo"),
          language: h.fetch(:language, "pt-BR")
        )
      end
    end
  end
end
