defmodule RinhaBackendV3.Payment do
  defstruct [
    :correlation_id,
    :amount,
    :requested_at,
    :provider
  ]
end
