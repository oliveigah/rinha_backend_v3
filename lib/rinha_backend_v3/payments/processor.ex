defmodule RinhaBackendV3.Payments.Processor do
  use GenServer

  alias RinhaBackendV3.Payment
  alias RinhaBackendV3.Payments.Queue
  alias RinhaBackendV3.Payments.ProviderStatusChecker
  alias RinhaBackendV3.Payments.Providers
  alias RinhaBackendV3.Payments.SummaryStorage

  def start_link(args) do
    GenServer.start_link(__MODULE__, args)
  end

  def init(_) do
    Process.send_after(self(), :process_payment, 0)
    {:ok, nil}
  end

  def handle_info(:process_payment, state) do
    case Queue.pop_next() do
      :empty ->
        :noop

      {index, %Payment{} = payment} ->
        current_provider = ProviderStatusChecker.get_current_provider()

        case Providers.process_payment(payment, current_provider) do
          :ok ->
            new_payment = %Payment{payment | provider: current_provider}
            true = SummaryStorage.write(new_payment)
            :ok

          :error ->
            Queue.insert(payment, index)
        end
    end

    Process.send_after(self(), :process_payment, 100)

    {:noreply, state}
  end
end
