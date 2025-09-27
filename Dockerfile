# 1. ETAPA DE CONSTRUCCIÓN: Compila el código fuente parcheado
FROM ruby:3.4.4-slim AS base
WORKDIR /app

# Instala dependencias del sistema base (incluyendo curl para instalar Node)
RUN apt-get update -qq && apt-get install -yq --no-install-recommends \
    build-essential libpq-dev git curl bash \
    && rm -rf /var/lib/apt/lists/*

# Instala la versión de Node.js que el proyecto espera (23.x)
RUN curl -fsSL https://deb.nodesource.com/setup_23.x | bash - \
    && apt-get install -y --no-install-recommends nodejs

# Ahora usamos el `npm` oficial para instalar `pnpm` globalmente
RUN npm install -g pnpm

# --- El resto del flujo es como lo teníamos optimizado ---

# Copia archivos de dependencias de Ruby y JS
COPY Gemfile Gemfile.lock package.json pnpm-lock.yaml /app/

# Instala dependencias de Ruby
RUN bundle install --jobs $(nproc) --without development test

# Instala dependencias de JavaScript usando pnpm
RUN pnpm install --frozen-lockfile

# Copia el resto del código fuente
COPY . .

# CRÍTICO: Elimina la tarea de desarrollo
RUN rm -f lib/tasks/auto_annotate_models.rake

# ***** NUEVA LÍNEA AQUÍ *****
# Inserta la configuración para evitar la inicialización de la DB durante la precompilación
RUN sed -i '/config.eager_load = true/a \  config.assets.initialize_on_precompile = false' config/environments/production.rb

# Precompila los assets para producción
ENV RAILS_ENV=production
RUN SECRET_KEY_BASE_DUMMY=1 bundle exec rake assets:precompile

# 2. ETAPA DE EJECUCIÓN: Imagen ligera final
FROM ruby:3.4.4-slim
WORKDIR /app

# Copia las dependencias y el código compilado de la etapa anterior
COPY --from=base /usr/local/bundle /usr/local/bundle
COPY --from=base /app /app

# Asegura que el entrypoint sea ejecutable
RUN chmod +x docker/entrypoints/rails.sh

ENTRYPOINT ["./docker/entrypoints/rails.sh"]

# El CMD por defecto es iniciar el servidor Rails
CMD ["bundle", "exec", "rails", "s", "-p", "3000", "-b", "0.0.0.0"]
