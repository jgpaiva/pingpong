defmodule Pingpong do
  @moduledoc """
  Documentation for Pingpong.
  """

  @doc """
  The pingpong server. It returns the ping along with its counter to the sender.

  ## Examples

  iex> a = spawn(fn -> Pingpong.pong() end); now = DateTime.utc_now(); send a, {:ping, 0, now, self()}; send a, {:ping, 1, now, self()}; {:pong, 0, _} = receive do a -> a end; {:pong, 1, _} = receive do a -> a end; true
  true

  """
  def pong do
    receive do
      {:ping, counter, timestamp, client} ->
        (fn ->
           diff = DateTime.diff(DateTime.utc_now(), timestamp, :millisecond)
           # uses :erlang.display instead of IO.puts so that it's displayed at the local node
           :erlang.display("PONG #{counter}, latency (ms): #{diff}")
           send(client, {:pong, counter, self()})
         end).()
    end

    pong()
  end

  @doc """
  The pingpong client. It sends `num_pings` pings to another process.

  ## Examples

  iex> a = self(); spawn(fn -> Pingpong.ping(a, 2) end); {:ping, 1, _, _} = receive do a -> a end; {:ping, 2, _, _} = receive do a -> a end; true
  true

  """
  def ping(server_pid, num_pings) do
    IO.puts("Sending pings to #{inspect(server_pid)}")

    Enum.map(1..num_pings, fn counter ->
      IO.puts("PING #{counter} #{DateTime.utc_now()}")
      send(server_pid, {:ping, counter, DateTime.utc_now(), self()})
      :timer.sleep(1000)
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
           true = Node.connect(:"server@pingpong_server_1.pingpong_net1")
           IO.puts("Available nodes: #{inspect(Node.list())}")
           IO.puts("Spawning link in server")

           server_pid =
             Node.spawn_link(:"server@pingpong_server_1.pingpong_net1", Pingpong, :pong, [])

           IO.puts("Starting client")
           ping(server_pid, 1000)
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
