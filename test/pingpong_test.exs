defmodule PingpongTest do
  use ExUnit.Case, async: true
  doctest Pingpong

  test "Statistics process replies back with statistics when it gets a :tick messages" do
    s = self()

    pong_pid =
      spawn(Pingpong, :statistics, [
        %{msgs: %{}, dup_err: 0, order_err: 0},
        fn x -> send(s, x) end
      ])

    send(pong_pid, {:tick, self()})

    receive do
      x -> x
    end
  end

  test "When we get 3 pings, the stats include 3 messages" do
    s = self()

    pong_pid =
      spawn(Pingpong, :statistics, [
        %{msgs: %{}, dup_err: 0, order_err: 0},
        fn x -> send(s, x) end
      ])

    Enum.each(1..3, fn counter ->
      send(pong_pid, {:ping, self(), counter, DateTime.utc_now()})
    end)

    send(pong_pid, {:tick, self()})

    receive do
      x -> "msgs: 3 dup_err: 0 order_err: 0" = x
    end
  end

  test "When we get pings with errors, the stats reflect that" do
    s = self()

    pong_pid =
      spawn(Pingpong, :statistics, [
        %{msgs: %{}, dup_err: 0, order_err: 0},
        fn x -> send(s, x) end
      ])

    send(pong_pid, {:ping, self(), 2, DateTime.utc_now()})
    send(pong_pid, {:ping, self(), 2, DateTime.utc_now()})
    send(pong_pid, {:ping, self(), 1, DateTime.utc_now()})

    send(pong_pid, {:tick, self()})

    receive do
      x -> "msgs: 3 dup_err: 1 order_err: 1" = x
    end
  end

  test "Pong receives message and sends info to client and stats pids" do
    s = self()
    pong_pid = spawn(fn -> Pingpong.pong(s) end)

    now = DateTime.utc_now()

    Enum.each(1..3, fn counter ->
      send(pong_pid, {:ping, s, counter, now})
    end)

    Enum.each(1..3, fn counter ->
      Enum.each(1..2, fn _ ->
        receive do
          {:pong, _, ^counter} -> true
          {:ping, ^s, ^counter, _} -> true
        end
      end)
    end)
  end
end
