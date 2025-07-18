defmodule RinhaBackendV3.Payments.Providers do
  alias RinhaBackendV3.Payment

  @provider_data %{
    default: Application.compile_env(:rinha_backend_v3, :default_provider),
    fallback: Application.compile_env(:rinha_backend_v3, :fallback_provider)
  }

  def failling?(provider) do
    url = ~c"#{@provider_data[provider].base_url}/payments/service-health"

    case :httpc.request(:get, {url, []}, [], []) do
      {:ok, {{_httpv, 200, _status_msg}, _headers, charlist_body}} ->
        case JSON.decode(to_string(charlist_body)) do
          {:ok, %{"failing" => failing?}} -> failing?
          _err -> true
        end

      _e ->
        true
    end
  end

  def process_payment(%Payment{} = p, provider) when provider in [:default, :fallback] do
    url = ~c"#{@provider_data[provider].base_url}/payments"

    body =
      %{
        "correlationId" => p.correlation_id,
        "amount" => p.amount,
        "requestedAt" => p.requested_at
      }
      |> JSON.encode!()
      |> to_charlist()

    case :httpc.request(:post, {url, [], ~c"application/json", body}, [], []) do
      {:ok, {{_httpv, 200, _status_msg}, _headers, _charlist_body}} ->
        :ok

      _err ->
        :error
    end
  end

  def process_payment(_payment, _provider), do: :error
end
