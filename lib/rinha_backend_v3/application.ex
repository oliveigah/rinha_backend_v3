defmodule RinhaBackendV3.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    connect_to_cluster(10000)

    children = [
      # Starts a worker by calling: RinhaBackendV3.Worker.start_link(arg)
      # {RinhaBackendV3.Worker, arg}
      {Finch,
       name: HttpClient,
       pools: %{
         :default => [size: 50, count: 1]
       }},
      RinhaBackendV3.Payments.SummaryStorage,
      RinhaBackendV3.Payments.ProviderStatusChecker,
      RinhaBackendV3.Payments.Queue,
      {
        Bandit,
        plug: RinhaBackendV3.HttpServer, port: System.fetch_env!("HTTP_SERVER_PORT")
        # thousand_island_options: [num_acceptors: 200]
      },
      init_processors()
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: RinhaBackendV3.Supervisor]
    Supervisor.start_link(List.flatten(children), opts)
  end

  defp init_processors() do
    count = System.fetch_env!("PROCESSORS_COUNT") |> String.to_integer()

    Enum.map(1..count, fn i ->
      Supervisor.child_spec({RinhaBackendV3.Payments.Processor, nil},
        id: {RinhaBackendV3.Payments.Processor, i}
      )
    end)
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
