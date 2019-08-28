defmodule Pingpong do
  @moduledoc """
  Documentation for Pingpong.
  """

  @doc """
  The pingpong server process. It receives the ping, calculates its latency and
  returns it along with its counter to the sender. It also sends the ping to
  the statistics process along with the latency to keep statistics.
  """
  def pong(stats_pid) do
    receive do
      {:ping, client_pid, counter, timestamp} ->
        (fn ->
           latency = DateTime.diff(DateTime.utc_now(), timestamp, :millisecond)
           # uses :erlang.display instead of IO.puts so that it's displayed at the local node
           send(client_pid, {:pong, self(), counter})
           send(stats_pid, {:ping, client_pid, counter, latency})
         end).()
    end

    pong(stats_pid)
  end

  def ticker(stats_pid) do
    :timer.sleep(1000)
    send(stats_pid, {:tick, self()})
    ticker(stats_pid)
  end

  def pong_entrypoint() do
    stats_pid =
      spawn(Pingpong, :statistics, [
        %{msgs: %{}, dup_err: 0, order_err: 0},
        fn x ->
          :erlang.display(x)
        end
      ])

    spawn(Pingpong, :ticker, [stats_pid])
    pong(stats_pid)
  end

  @doc """
  The statistics process. Keeps track of the messages, calculates if they
  were delivered with errors and returns statistics to be printed.
  """
  def statistics(state, print_f) do
    receive do
      {:ping, client_pid, counter, _latency} ->
        statistics(update_pong_state(state, {counter, client_pid}), print_f)

      {:tick, _sender_pid} ->
        print_f.("msgs: #{count_msgs(state)}")
    end

    statistics(state, print_f)
  end

  def count_msgs(%{msgs: msgs}) do
    Enum.sum(Enum.map(msgs, fn {_k, v} -> Enum.count(v) end))
  end

  # WIP: needs to be connected to the server
  @doc """
  Updates the state based on the consistency rules. Detects out of order messages as well as duplicates.

  ## Examples
  iex> Pingpong.update_pong_state(%{msgs: %{a: [0]}, dup_err: 0, order_err: 0}, {1, :a})
  %{msgs: %{a: [1, 0]}, dup_err: 0, order_err: 0}

  iex> Pingpong.update_pong_state(%{msgs: %{a: [1, 0]}, dup_err: 0, order_err: 0}, {0, :a})
  %{msgs: %{a: [1, 0]}, dup_err: 1, order_err: 0}

  iex> Pingpong.update_pong_state(%{msgs: %{a: [3]}, dup_err: 0, order_err: 0}, {0, :a})
  %{msgs: %{a: [3, 0]}, dup_err: 0, order_err: 1}

  iex> Pingpong.update_pong_state(%{msgs: %{}, dup_err: 0, order_err: 0}, {3, :a})
  %{msgs: %{a: [3]}, dup_err: 0, order_err: 0}

  iex> Pingpong.update_pong_state(%{msgs: %{a: [3]}, dup_err: 0, order_err: 1}, {3, :b})
  %{msgs: %{a: [3], b: [3]}, dup_err: 0, order_err: 1}
  """
  def update_pong_state(state, {counter, client}) do
    case state.msgs do
      %{^client => [h | _] = old} when h == counter - 1 ->
        %{state | msgs: %{state.msgs | client => [counter | old]}}

      %{^client => old} ->
        if counter in old do
          %{state | msgs: %{state.msgs | client => old}, dup_err: state.dup_err + 1}
        else
          %{
            state
            | msgs: %{state.msgs | client => Enum.sort([counter | old], &(&1 >= &2))},
              order_err: state.order_err + 1
          }
        end

      _ ->
        %{state | msgs: Map.put(state.msgs, client, [counter])}
    end
  end

  @doc """
  The pingpong client. It sends `num_pings` pings to another process.

  ## Examples

  iex> a = self(); spawn(fn -> Pingpong.ping(a, 2) end); {:ping, _, 1, _} = receive do a -> a end; {:ping, _, 2, _} = receive do a -> a end; true
  true

  """
  def ping(server_pid, num_pings) do
    IO.puts("Sending pings to #{inspect(server_pid)}")

    Enum.each(1..num_pings, fn counter ->
      #IO.puts("PING #{counter} #{DateTime.utc_now()}")
      send(server_pid, {:ping, self(), counter, DateTime.utc_now()})
      :timer.sleep(10)
    end)
  end

  def server_loop do
    receive do
      a -> a
    end

    server_loop()
  end

  def main(args) do
    {valid_options, _args, _invalid_options} =
      OptionParser.parse(args,
        strict: [
          help: :boolean,
          mode: :string
        ]
      )

    case valid_options do
      [mode: "server"] ->
        (fn ->
           {:ok, _} = Node.start(:"server@pingpong_server_1.pingpong_net1")
           Node.set_cookie(String.to_atom("superpingpongcookie"))
           IO.puts("Running server at #{inspect({Node.self(), Node.get_cookie()})}")
           server_loop()
         end).()

      [mode: "client"] ->
        (fn ->
           {:ok, _} = Node.start(:"client@pingpong_client_1.pingpong_net1")
           Node.set_cookie(String.to_atom("superpingpongcookie"))
           IO.puts("Running client at #{inspect({Node.self(), Node.get_cookie()})}")
           result = Node.connect(:"server@pingpong_server_1.pingpong_net1")
           # retry in case connect didn't work
           unless result do
             true = Node.connect(:"server@pingpong_server_1.pingpong_net1")
           end

           IO.puts("Available nodes: #{inspect(Node.list())}")
           IO.puts("Spawning link in server")

           server_pid =
             Node.spawn_link(
               :"server@pingpong_server_1.pingpong_net1",
               Pingpong,
               :pong_entrypoint,
               []
             )

           IO.puts("Starting client")
           ping(server_pid, 100_000)
         end).()

      _ ->
        IO.puts("""
        usage: pingpong --mode <one of "server" or "client">
        Do a ping pong
        -- Started on node #{node()}
        """)
    end
  end
end
