# InputParser

Processes the file "queries.txt" and converts the 2 space seperated integers into a map entry as key and value.Place "queries.txt" in the main project folder,of the following format-

```
x1 x2
y1 y2
z1 z2
```

(Currently for 3 queries,can expand by changing the value of `n` in `obtain_queries/0` in `InputParser`(lib/input_parser.ex))

INSTRUCTIONS-

1. For running in normal mode-

run `bash script/normal_parse.sh`

2. For running in debug mode-

run `bash script/debug.sh`

and check `log/debug.log`

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `input_parser` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:input_parser, "~> 0.1.0"}
  ]
end
```

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at [https://hexdocs.pm/input_parser](https://hexdocs.pm/input_parser).

