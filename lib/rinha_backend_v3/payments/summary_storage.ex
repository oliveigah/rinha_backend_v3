defmodule RinhaBackendV3.Payments.SummaryStorage do
  use GenServer

  alias RinhaBackendV3.Payment

  def init(_) do
    :ets.new(__MODULE__, [
      :ordered_set,
      :public,
      :named_table,
      decentralized_counters: true,
      write_concurrency: true
    ])

    {:ok, nil}
  end

  def start_link(args) do
    GenServer.start_link(__MODULE__, args, name: __MODULE__)
  end

  def delete(%Payment{} = p),
    do: :ets.delete(__MODULE__, p.requested_at <> "_" <> p.correlation_id)

  def write(%Payment{} = p),
    do:
      :ets.insert(
        __MODULE__,
        {p.requested_at <> "_" <> p.correlation_id, p.provider, p.amount}
      )

  def get_global_summary(from, to) do
    all_nodes = Node.list([:this, :visible])

    {resps, _badnodes} =
      :rpc.multicall(all_nodes, __MODULE__, :get_summary, [from, to], :infinity)

    Enum.reduce(
      resps,
      %{
        default: %{totalRequests: 0, totalAmount: 0.0},
        fallback: %{totalRequests: 0, totalAmount: 0.0}
      },
      fn %{
           default: %{
             totalRequests: default_remote_total_reqs,
             totalAmount: default_remote_total_amount
           },
           fallback: %{
             totalRequests: fallback_remote_total_reqs,
             totalAmount: fallback_remote_total_amount
           }
         },
         acc ->
        acc
        |> update_in([:default, :totalRequests], fn t -> t + default_remote_total_reqs end)
        |> update_in([:default, :totalAmount], fn t ->
          Float.round(t + default_remote_total_amount, 2)
        end)
        |> update_in([:fallback, :totalRequests], fn t -> t + fallback_remote_total_reqs end)
        |> update_in([:fallback, :totalAmount], fn t ->
          Float.round(t + fallback_remote_total_amount, 2)
        end)
      end
    )
  end

  def get_summary(nil, nil) do
    __MODULE__
    |> :ets.tab2list()
    |> parse_to_summary()
  end

  def get_summary(from, to) do
    and_also_spec =
      cond do
        from != nil and to != nil ->
          {
            :andalso,
            {:>=, :"$1", from},
            # need to suffix zzzzz here to not exclude records with the exactly ts upperbound
            {:"=<", :"$1", to <> "zzzzzz"}
          }

        from == nil and to != nil ->
          {
            :andalso,
            # need to suffix zzzzz here to not exclude records with the exactly ts upperbound
            {:"=<", :"$1", to <> "zzzzzz"}
          }

        from != nil and to == nil ->
          {
            :andalso,
            {:>=, :"$1", from}
          }
      end

    match_spec = [
      {
        {:"$1", :"$2", :"$3"},
        [and_also_spec],
        [:"$_"]
      }
    ]

    __MODULE__
    |> :ets.select(match_spec)
    |> parse_to_summary()
  end

  def parse_to_summary(rec_list) do
    rec_list
    |> Enum.reduce(
      %{
        default: %{totalRequests: 0, totalAmount: 0.0},
        fallback: %{totalRequests: 0, totalAmount: 0.0}
      },
      fn {_k, provider, amount}, acc ->
        acc
        |> update_in([provider, :totalRequests], fn t -> t + 1 end)
        |> update_in([provider, :totalAmount], fn t -> t + amount end)
      end
    )
    |> update_in([:default, :totalAmount], fn t -> Float.round(t, 2) end)
    |> update_in([:fallback, :totalAmount], fn t -> Float.round(t, 2) end)
  end

  def flush(), do: :ets.delete_all_objects(__MODULE__)
end
