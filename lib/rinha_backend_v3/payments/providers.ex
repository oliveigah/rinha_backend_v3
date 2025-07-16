defmodule RinhaBackendV3.Payments.Providers do
  alias RinhaBackendV3.Payment

  @provider_data %{
    default: Application.compile_env(:rinha_backend_v3, :default_provider),
    fallback: Application.compile_env(:rinha_backend_v3, :fallback_provider)
  }

  def failling?(provider) do
    req = Finch.build(:get, "#{@provider_data[provider].base_url}/payments/service-health")

    case Finch.request(req, HttpClient) do
      {:ok, %Finch.Response{body: str_body, status: 200}} ->
        case JSON.decode(str_body) do
          {:ok, %{"failing" => failing?}} -> failing?
          _err -> true
        end

      _ ->
        true
    end
  end

  def process_payment(%Payment{} = p, provider) when provider in [:default, :fallback] do
    body = %{
      "correlationId" => p.correlation_id,
      "amount" => p.amount,
      "requestedAt" => p.requested_at
    }

    req =
      Finch.build(
        :post,
        "#{@provider_data[provider].base_url}/payments",
        [{"Content-Type", "application/json"}],
        JSON.encode!(body),
        []
      )

    case Finch.request(req, HttpClient) do
      {:ok, %Finch.Response{status: 200}} ->
        :ok

      _err ->
        :error
    end
  end

  def process_payment(_payment, _provider), do: :error
end
