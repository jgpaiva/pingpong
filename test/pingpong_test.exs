defmodule PingpongTest do
  use ExUnit.Case, async: true
  doctest Pingpong

  test "Pong replies back with statistics when it gets a :tick messages" do
    pong_pid = spawn(Pingpong, :pong, [])
    send(pong_pid, {:tick, self()})
    receive do
      {:stats, ^pong_pid, stats} -> stats
    end
  end

  @tag :skip
  test "When Pong gets 3 pings, the stats include 3 messages" do
    pong_pid = spawn(Pingpong, :pong, [])
    Enum.map(1..3, fn counter -> send(pong_pid, {:ping, self(), counter, DateTime.utc_now()}) end)
    send(pong_pid, {:tick, self()})
    receive do
      {:stats, ^pong_pid, stats} -> %{num_msgs: 3} = stats
    end
  end
end
