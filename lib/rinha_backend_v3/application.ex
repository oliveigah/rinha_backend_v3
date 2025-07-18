defmodule RinhaBackendV3.Application do
  use Application

  alias RinhaBackendV3.Payments.SummaryStorage
  alias RinhaBackendV3.Payments.ProviderStatusChecker
  alias RinhaBackendV3.Payments.PendingQueue
  alias RinhaBackendV3.HttpServer
  alias RinhaBackendV3.Payments.Processor

  def start(_type, _args) do
    connect_to_cluster(10)

    children = [
      SummaryStorage,
      ProviderStatusChecker,
      PendingQueue,
      {Bandit, plug: HttpServer, port: System.fetch_env!("HTTP_SERVER_PORT")},
      handle_processors()
    ]

    opts = [strategy: :one_for_one, name: RinhaBackendV3.Supervisor]
    Supervisor.start_link(List.flatten(children), opts)
  end

  defp handle_processors() do
    count = System.fetch_env!("PROCESSORS_COUNT") |> String.to_integer()
    Enum.map(1..count, fn i -> Supervisor.child_spec({Processor, nil}, id: {Processor, i}) end)
  end

  defp connect_to_cluster(timeout) do
    do_connect_to_cluster(timeout, System.monotonic_time(:second))
  end

  defp do_connect_to_cluster(timeout, start) do
    nodes =
      System.fetch_env!("BOOTSTRAP_NODES")
      |> String.split(",")
      |> Enum.reject(fn e -> e == "" end)

    sucess = Enum.all?(nodes, fn n -> Node.connect(String.to_atom(n)) == true end)

    if sucess do
      :ok
    else
      if System.monotonic_time(:second) - start > timeout do
        raise "TIEMOUT! Could not connect to cluster!"
      else
        Process.sleep(:timer.seconds(1))
        do_connect_to_cluster(timeout, start)
      end
    end
  end
end
