# ServerBenchmark

Lists of sizes from 1 to 10_000_000 are made and stored as the state of a GenServer Process and the heap consumption of the GenServer is observed. Based on the results the doubling the schedule would not be an acceptable method to implement a circular queue as the memory consumption can increase significantly.


The Results obtained are as follows:

|  List length          | Heap Size        |
| ---------- | -------- |
| 1          | 233      |
| 10         | 233      |
| 100        | 609      | 
| 1000       | 2586     |
| 10,000     | 28690    |
| 100,000    | 318187   |
| 1,000,000  | 2072833  |
| 10,000,000 | 22177879 |


## Installation


If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `heap_size` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:heap_size, "~> 0.1.0"}
  ]
end
```

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at [https://hexdocs.pm/server_benchmark](https://hexdocs.pm/server_benchmark).


## Running Benchmark
From Project root run
mix run -e HeapSize.get_heap_sizes
