defmodule RinhaBackendV3Test do
  use ExUnit.Case

  alias RinhaBackendV3.Payment
  alias RinhaBackendV3.Payments.SummaryStorage

  test "simple ets match all" do
    [
      %Payment{
        amount: 10.1,
        correlation_id: "1",
        provider: :default,
        requested_at: "2025-07-16T01:46:00.000000Z"
      },
      %Payment{
        amount: 20.2,
        correlation_id: "2",
        provider: :default,
        requested_at: "2025-07-16T01:47:00.000000Z"
      },
      %Payment{
        amount: 30.3,
        correlation_id: "3",
        provider: :default,
        requested_at: "2025-07-16T01:48:00.000000Z"
      },
      %Payment{
        amount: 40.4,
        correlation_id: "4",
        provider: :fallback,
        requested_at: "2025-07-16T01:49:00.000000Z"
      },
      %Payment{
        amount: 50.5,
        correlation_id: "5",
        provider: :fallback,
        requested_at: "2025-07-16T01:50:00.000000Z"
      }
    ]
    |> Enum.each(fn p ->
      SummaryStorage.write(p)
    end)

    assert %{
             default: %{
               totalRequests: 3,
               totalAmount: 60.6
             },
             fallback: %{
               totalRequests: 2,
               totalAmount: 90.9
             }
           } = SummaryStorage.get_summary(nil, nil)
  end

  test "ets match time window" do
    {:ok, first_ts, 0} = DateTime.from_iso8601("2025-07-16T01:46:00.000000Z")
    base_amount = 10.0

    all_payments =
      Enum.map(0..1000, fn i ->
        %Payment{
          amount: base_amount + i / 10,
          correlation_id: UUIDv7.generate(),
          provider: if(rem(i, 2) == 0, do: :default, else: :fallback),
          requested_at: DateTime.add(first_ts, i, :minute) |> DateTime.to_iso8601()
        }
      end)

    Enum.each(all_payments, fn p -> SummaryStorage.write(p) end)

    :timer.tc(fn ->
      SummaryStorage.get_summary(
        "2025-07-16T01:47:00.000000Z",
        "2025-07-16T01:50:00.000000Z"
      )
    end)

    SummaryStorage.flush()

    all_payments =
      Enum.map(0..1000, fn i ->
        %Payment{
          amount: base_amount + i / 10,
          correlation_id: UUIDv7.generate(),
          provider: if(rem(i, 2) == 0, do: :default, else: :fallback),
          requested_at: DateTime.add(first_ts, i, :minute) |> DateTime.to_iso8601()
        }
      end)

    Enum.each(all_payments, fn p -> SummaryStorage.write(p) end)

    assert %{
             default: %{
               totalRequests: 2,
               totalAmount: 20.6
             },
             fallback: %{
               totalRequests: 2,
               totalAmount: 20.4
             }
           } =
             SummaryStorage.get_summary(
               "2025-07-16T01:47:00.000000Z",
               "2025-07-16T01:50:00.000000Z"
             )

    SummaryStorage.flush()
  end

  test "ets match from or to nil" do
    [
      %Payment{
        amount: 10.1,
        correlation_id: "1",
        provider: :default,
        requested_at: "2025-07-16T01:46:00.000000Z"
      },
      %Payment{
        amount: 20.2,
        correlation_id: "2",
        provider: :default,
        requested_at: "2025-07-16T01:47:00.000000Z"
      },
      %Payment{
        amount: 30.3,
        correlation_id: "3",
        provider: :default,
        requested_at: "2025-07-16T01:48:00.000000Z"
      },
      %Payment{
        amount: 40.4,
        correlation_id: "4",
        provider: :fallback,
        requested_at: "2025-07-16T01:49:00.000000Z"
      },
      %Payment{
        amount: 50.5,
        correlation_id: "5",
        provider: :fallback,
        requested_at: "2025-07-16T01:50:00.000000Z"
      }
    ]
    |> Enum.each(fn p ->
      SummaryStorage.write(p)
    end)

    assert %{
             default: %{
               totalRequests: 2,
               totalAmount: 50.5
             },
             fallback: %{
               totalRequests: 2,
               totalAmount: 90.9
             }
           } = SummaryStorage.get_summary("2025-07-16T01:47:00.000000Z", nil)

    assert %{
             default: %{
               totalRequests: 3,
               totalAmount: 60.6
             },
             fallback: %{
               totalRequests: 1,
               totalAmount: 40.4
             }
           } = SummaryStorage.get_summary(nil, "2025-07-16T01:49:00.000000Z")
  end
end
