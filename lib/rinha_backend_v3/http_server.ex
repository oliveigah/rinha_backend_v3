defmodule RinhaBackendV3.HttpServer do
  use Plug.Router

  alias RinhaBackendV3.Payment
  alias RinhaBackendV3.Payments.Queue
  alias RinhaBackendV3.Payments.SummaryStorage

  plug(:match)

  plug(Plug.Parsers,
    parsers: [:json],
    pass: ["application/json"],
    json_decoder: JSON
  )

  plug(:dispatch)

  post "/payments" do
    body = conn.body_params

    p = %Payment{
      amount: Map.fetch!(body, "amount"),
      correlation_id: Map.fetch!(body, "correlationId"),
      # correlation_id: UUIDv7.generate(),
      requested_at: DateTime.utc_now() |> DateTime.to_iso8601()
    }

    :ok = Queue.insert(p)

    send_resp(conn, 200, "")
  end

  get "/payments-summary" do
    conn = fetch_query_params(conn)
    resp = SummaryStorage.get_global_summary(conn.query_params["from"], conn.query_params["to"])

    conn
    |> put_resp_content_type("application/json")
    |> send_resp(200, JSON.encode!(resp))
  end

  get "/health" do
    send_resp(conn, 200, "")
  end

  match _ do
    send_resp(conn, 404, "route not found")
  end
end
