# ServerBenchmark

A GenServer process is created and a number of other lightweight processes are spawned that will continuously query the GenServer for information.
The number of queries (calls) handled by the GenServer are measured.

Measurements have been done for message sizes of 1, 100, 1000 and 8000 bytes and ligweight processes number 1, 1000, 2000 and 10000.


The Results obtained are as follows:

|            | 1        | 1000     | 2000     | 10000    |
| ---------- | -------- | -------- | -------- | -------- |
| 1 Byte     | 14312076 | 14744749 | 12073071 | 10938000 |
| 100 Bytes  | 14935120 | 14364395 | 11811121 | 11364701 |
| 1000 Bytes | 14449290 | 14427389 | 12508351 | 10983298 |
| 8000 Bytes | 14257596 | 14252970 | 12252687 | 10359615 |


## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `server_benchmark` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:server_benchmark, "~> 0.1.0"}
  ]
end
```

Needs pwgen bash command installed

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at [https://hexdocs.pm/server_benchmark](https://hexdocs.pm/server_benchmark).




