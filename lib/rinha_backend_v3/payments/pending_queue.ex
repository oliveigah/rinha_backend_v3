defmodule RinhaBackendV3.Payments.PendingQueue do
  use GenServer

  alias RinhaBackendV3.Payment

  def start_link(args) do
    GenServer.start_link(__MODULE__, args, name: __MODULE__)
  end

  def init(_args) do
    :ok = init_index_counter()

    :ets.new(__MODULE__, [
      :ordered_set,
      :public,
      :named_table,
      decentralized_counters: true
    ])

    {:ok, nil}
  end

  def init_index_counter() do
    :persistent_term.put({:index, __MODULE__}, :atomics.new(1, signed: false))
  end

  def get_next_index() do
    {:index, __MODULE__}
    |> :persistent_term.get()
    |> :atomics.add_get(1, 1)
  end

  def insert(%Payment{} = p) do
    true = :ets.insert(__MODULE__, {get_next_index(), p})
    :ok
  end

  def insert(%Payment{} = p, index) do
    :ets.insert(__MODULE__, {index, p})
  end

  def take_next() do
    case :ets.first(__MODULE__) do
      :"$end_of_table" ->
        :empty

      index ->
        case :ets.take(__MODULE__, index) do
          [] ->
            # race condition, try to fetch next
            take_next()

          [{^index, payment}] ->
            {index, payment}
        end
    end
  end
end
