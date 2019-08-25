# Pingpong

Ping pong server and client combined with [pumba](https://github.com/alexei-led/pumba) to shine some light on the delivery guarantees of elixir / erlang.

# What does it do

It runs a client and server. The client that sends messages with its timestamp and a monotonic counter. The server prints the counters of messages, along with the delay it observes messages have (timestamps are reliable as long as all this runs on a single machine).
While the client and the server are running, pumba is injecting network delays as well as network loss.

# How to run

Start the experiment with `docker-compose build && docker-compose run chaos`, observe the experiment with `docker-compose logs -f`, stop the experiment with `docker-compose down`.


