# Multiplier

Fetches the queries from input_parser and stores the multiplication results in "results.txt".Place "queries.txt" in the main project folder.

Instructions-


run `bash script/multiplying.sh`

EXPECTED OUTPUT-

```
$ bash script/multiplying.sh 
Loading from config.exs in multiplier
Resolving Hex dependencies...
Dependency resolution completed:
  logger_file_backend 0.0.10
Loading from config.exs in multiplier
Starting application in InputParser.Application(lib/input_parser/application.ex)
Input Parser Initialised and Queries are Obtained
Starting application in Multiplier.Application(lib/multiplier/application.ex)
Multiplier initialised
Multiplying....
Done calculating,please open results.txt
```


## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `multiplier` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:multiplier, "~> 0.1.0"}
  ]
end
```

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at [https://hexdocs.pm/multiplier](https://hexdocs.pm/multiplier).

