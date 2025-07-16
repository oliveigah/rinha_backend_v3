import Config

config :rinha_backend_v3, :default_provider, %{
  base_url: "http://payment-processor-default:8080"
}

config :rinha_backend_v3, :fallback_provider, %{
  base_url: "http://payment-processor-fallback:8080"
}

import_config "#{config_env()}.exs"
