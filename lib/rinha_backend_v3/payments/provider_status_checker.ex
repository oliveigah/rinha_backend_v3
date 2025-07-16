defmodule RinhaBackendV3.Payments.ProviderStatusChecker do
  use GenServer

  alias RinhaBackendV3.Payments.Providers

  def start_link(opts) do
    case GenServer.start_link(__MODULE__, opts, name: {:global, __MODULE__}) do
      {:ok, pid} ->
        {:ok, pid}

      {:error, {:already_started, pid}} ->
        {:ok, pid}

      {:error, :killed} ->
        :ignore
    end
  end

  def init(_) do
    :ok = check_status()
    Process.send_after(self(), :check, :timer.seconds(5))
    {:ok, nil}
  end

  def check_status() do
    cond do
      Providers.failling?(:default) == false ->
        set_current_provider(:default)

      Providers.failling?(:fallback) == false ->
        set_current_provider(:fallback)

      true ->
        set_current_provider(:none)
    end

    :ok
  end

  def handle_info(:check, state) do
    check_status()
    Process.send_after(self(), :check, :timer.seconds(5))
    {:noreply, state}
  end

  def set_current_provider(provider) do
    all_nodes = Node.list([:this, :visible])

    Enum.each(all_nodes, fn n ->
      :rpc.call(n, __MODULE__, :do_set_current_provider, [provider])
    end)
  end

  def do_set_current_provider(provider) do
    :persistent_term.put({__MODULE__, :available}, provider)
  end

  def get_current_provider() do
    :persistent_term.get({__MODULE__, :available}, :default)
  end
end
