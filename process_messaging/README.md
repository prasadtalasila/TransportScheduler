# ServerBenchmark

A GenServer process is created and a number of other lightweight processes are spawned that will continuously query the GenServer for information.
The number of queries (calls) handled by the GenServer are measured.

Measurements have been done for message sizes of 1, 100, 1000 and 8000 bytes and ligweight processes number 1, 1000, 2000 and 10000.


The Results obtained are as follows for itinerary of length 0 to 64

| | 0 | 1 | 2 | 4 | 8 | 16 | 32 | 64 |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| 1 process | 11249897 | 9932330 | 8787840 | 7323750 | 5486817 | 3810714 | 2339269 | 1300506 |
| 2 processes | 9869907 | 9068163 | 8288289 | 7274611 | 5620597 | 4041439 | 2877668 | 1715370 |
| 3 processes | 12037226 | 10993401 | 9977193 | 8276070 | 6467317 | 4849807 | 3442193 | 1920776 |
| 4 processes | 13298796 | 12124583 | 10880741 | 9237775 | 7197589 | 5409037 | 3615453 | 2158088 |
| 5 processes | 13716034 | 12869106 | 11815871 | 9628078 | 7669563 | 5757612 | 3787756 | 2219225 |
| 6 processes | 14520759 | 13592870 | 12151406 | 10248779 | 7805546 | 5844899 | 3813131 | 2250892 |
| 10 processes | 16156547 | 15148990 | 14327176 | 12402111 | 9185833 | 6349878 | 4060980 | 2181640 |
| 100 processes | 19562476 | 16176602 | 13829889 | 11435838 | 8441885 | 5715467 | 3587490 | 2390913 |
| 1000 processes | 15851485 | 14727882 | 12477563 | 9707851 | 7377805 | 4429636 | 2875461 | 1789500 |
| 10000 processes | 11715311 | 10487324 | 9371667 | 7340266 | 5719350 | 4171329 | 2883458 | 1831476 |




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



## Running Benchmark
From Project root run
./benchmark.sh

The results are written into benchmarks.txt
