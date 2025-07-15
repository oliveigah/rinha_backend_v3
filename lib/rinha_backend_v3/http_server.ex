defmodule HttpServer do
  use Plug.Router

  plug(:match)

  plug(Plug.Parsers,
    parsers: [:json],
    pass: ["application/json"],
    json_decoder: JSON
  )

  plug(:dispatch)

  post "/payments" do
    body = conn.body_params

    required = [:correlationId, :amount]

    body_rules = %{
      correlationId: [
        fn v -> is_bitstring(v) end
      ],
      amount: [
        fn v -> is_float(v) end
      ]
    }

    cond do
      not Enum.all?(required, fn k -> Map.get(body, Atom.to_string(k)) end) ->
        send_resp(conn, 422, "")

      not Enum.all?(body_rules, fn {k, rules} ->
        Enum.all?(rules, fn f -> f.(body[Atom.to_string(k)]) end)
      end) ->
        send_resp(conn, 400, "")

      true ->
        send_resp(conn, 200, JSON.encode!(body))
    end
  end

  match _ do
    send_resp(conn, 404, "route not found")
  end
end
