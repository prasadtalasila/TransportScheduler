# Multiplier

Fetches the queries from input_parser and stores the multiplication results in "results.txt".Place "queries.txt" in the main project folder.

Instructions-


run `bash script/multiplying.sh`

Depends on input_parser and hence the following needs to be present in the `deps/0` function of `mix.exs` -

`{:input_parser, in_umbrella: true}`


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

