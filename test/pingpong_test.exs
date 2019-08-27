defmodule PingpongTest do
  use ExUnit.Case, async: true
  doctest Pingpong

  test "Pong replies back with statistics when it gets a :tick messages" do
    s = self()
    pong_pid = spawn(Pingpong, :pong_state_actor,
      [%{msgs: %{}, dup_err: 0, order_err: 0}, fn x -> send(s, x) end])
    send(pong_pid, {:tick, self()})

    receive do
      x -> x
    end
  end

  test "When Pong gets 3 pings, the stats include 3 messages" do
    s = self()
    pong_pid = spawn(Pingpong, :pong_state_actor,
      [%{msgs: %{}, dup_err: 0, order_err: 0}, fn x -> send(s, x) end])

    Enum.each(1..3, fn counter ->
      send(pong_pid, {:ping, self(), counter, DateTime.utc_now()})
    end)

    send(pong_pid, {:tick, self()})

    receive do
      "3" -> true
    end
  end
end
