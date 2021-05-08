# Pingpong

Pretty terrible ping pong server and client combined with [pumba](https://github.com/alexei-led/pumba) to shine some light on the delivery guarantees of elixir / erlang (see sections 10.8 and 10.9 on [this](http://erlang.org/faq/academic.html) page for what the official documentation has to say about this).

# What does it do

It runs a client and server. The client that sends messages with its timestamp and a monotonic counter. The server prints the counters of messages, along with the delay it observes messages have (timestamps are reliable as long as all this runs on a single machine).
While the client and the server are running, pumba is injecting network delays as well as network loss.

# How to run

Start the experiment with `docker-compose build && docker-compose run chaos`, observe the experiment with `docker-compose logs -f`, stop the experiment with `docker-compose down`.

# Conclusions

From this experiment, when there are no process/node failures, messages between two processes are delivered in order and without loss.

# Future work

* Understand the behavior when processes may get restarted by a local supervisor.
* Understand the behavior when using a process registry like [Horde](https://hexdocs.pm/horde/getting_started.html).
* Understand the behavior when nodes are killed and processes get restarted on another node by something like [libcluster](https://hexdocs.pm/libcluster/readme.html).
