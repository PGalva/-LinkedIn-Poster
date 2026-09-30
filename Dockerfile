# Imagem da API do LinkedIn Poster.
# Receita: "pegue um Linux com Ruby, instale as gems, copie o código, rode o servidor".
FROM ruby:3.3-slim

# puma e nio4r compilam extensões em C -> precisam de compilador.
RUN apt-get update \
 && apt-get install -y --no-install-recommends build-essential \
 && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Seu Gemfile.lock foi gerado com Bundler 4 -> atualizamos o RubyGems e instalamos a mesma versão.
RUN gem update --system --no-document && gem install bundler:4.0.3 --no-document

# Copiamos SÓ o Gemfile primeiro: o Docker guarda esta etapa em cache e não
# reinstala as gems toda vez que você muda uma linha de código.
COPY Gemfile Gemfile.lock ./
RUN bundle install

COPY . .

EXPOSE 9292

# -o 0.0.0.0 é obrigatório: sem isso o servidor só escuta "dentro" do container
# e o seu navegador/curl não consegue alcançá-lo.
CMD ["bundle", "exec", "rackup", "-o", "0.0.0.0", "-p", "9292"]
