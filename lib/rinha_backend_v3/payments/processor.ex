defmodule RinhaBackendV3.Payments.Processor do
  use GenServer

  alias RinhaBackendV3.Payment
  alias RinhaBackendV3.Payments.PendingQueue
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
    current_provider = ProviderStatusChecker.get_current_provider()

    queue_resp =
      if current_provider == :none,
        do: :noop,
        else: PendingQueue.take_next()

    case queue_resp do
      {_index, %Payment{} = payment} ->
        new_payment = %Payment{
          payment
          | provider: current_provider,
            requested_at:
              DateTime.utc_now() |> DateTime.truncate(:millisecond) |> DateTime.to_iso8601()
        }

        case Providers.process_payment(new_payment, current_provider) do
          :ok ->
            true = SummaryStorage.write(new_payment)
            :ok

          :error ->
            PendingQueue.insert(payment)
        end

      _ ->
        :noop
    end

    Process.send_after(self(), :process_payment, 1)

    {:noreply, state}
  end
end
