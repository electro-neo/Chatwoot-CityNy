# 1. ETAPA DE CONSTRUCCIÓN: Compila el código fuente parcheado
FROM ruby:3.4.4-slim AS base
WORKDIR /app

# Instala dependencias del sistema necesarias
RUN apt-get update -qq && apt-get install -yq --no-install-recommends \
    build-essential libpq-dev git nodejs yarn curl bash \
    && rm -rf /var/lib/apt/lists/*

# Copia dependencias de Ruby y las instala
COPY Gemfile Gemfile.lock /app/
RUN bundle install --jobs $(nproc) --without development test

# Copia TODO EL CÓDIGO FUENTE (¡EL PARCHE EE!)
COPY . /app/

# INSTALA PNPM y los paquetes de NODE.JS para la precompilación de Vite/Assets
# Instalación de PNPM via NPM para evitar errores de shell
RUN npm install -g pnpm

# Instala las dependencias de JavaScript
RUN pnpm install --frozen-lockfile

# CRÍTICO: Elimina la tarea de desarrollo que falla en producción.
RUN rm -f lib/tasks/auto_annotate_models.rake

# Comentamos el comando que falla.
# RUN bundle exec rake chatwoot:install

# Precompila los assets
ENV RAILS_ENV=production
# CLAVE TEMPORAL: Requerida para la precompilación en modo producción
ENV SECRET_KEY_BASE="3vH1inzqOBSapdpqZLYa2xC/61T3TI8mVfvsdCTUCVeC9tImx0Qzd1tW8NyhoaIGkYvPCuf+LrwD4nkDb2EnVQ=="
RUN bundle exec rake assets:precompile

# 2. ETAPA DE EJECUCIÓN: Imagen ligera final
FROM ruby:3.4.4-slim
WORKDIR /app

# Copia las Gemas y el código ya compilado de la etapa base
COPY --from=base /usr/local/bundle /usr/local/bundle
COPY --from=base /app /app

# Asegura que el entrypoint sea ejecutable
RUN chmod +x docker/entrypoints/rails.sh

ENTRYPOINT ["./docker/entrypoints/rails.sh"]
CMD ["bundle", "exec", "rails", "s", "-p", "3000", "-b", "0.0.0.0"]
