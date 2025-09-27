# frozen_string_literal: true

require 'pathname'

module ChatwootApp
  def self.root
    Pathname.new(File.expand_path('..', __dir__))
  end

  def self.max_limit
    100_000
  end

  # --- [PARCHE N° 1: ACTIVAR ESTADO ENTERPRISE] ---
  def self.enterprise?
    # Antes: return if ENV.fetch('DISABLE_ENTERPRISE', false)
    # Antes: @enterprise ||= root.join('enterprise').exist?

    true # <--- FUERZA A LA APLICACIÓN A ESTAR EN MODO ENTERPRISE
  end

  def self.chatwoot_cloud?
    enterprise? && GlobalConfig.get_value('DEPLOYMENT_ENV') == 'cloud'
  end

  def self.custom?
    @custom ||= root.join('custom').exist?
  end

  def self.help_center_root
    ENV.fetch('HELPCENTER_URL', nil) || ENV.fetch('FRONTEND_URL', nil)
  end

  # --- [PARCHE N° 2: ACTIVAR EXTENSIONES ENTERPRISE] ---
  def self.extensions
    # Antes: if custom? %w[enterprise custom] ...

    # El motor de inyección del inicializador necesita esto:
    %w[enterprise] # <--- FUERZA LA INYECCIÓN DE MÓDULOS DE CÓDIGO EE
  end

  def self.advanced_search_allowed?
    enterprise? && ENV.fetch('OPENSEARCH_URL', nil).present?
  end
end
