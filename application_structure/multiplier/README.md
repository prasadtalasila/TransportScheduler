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


For more detailed output of sequence of loads on multiplier with dependency on inputparser,update `script/multiplying.sh` by adding `MIX_DEBUG=1` flag-

The following is a log of running the command with MIX_DEBUG flag set to `1` or `true`.

```
$ MIX_DEBUG=1 mix multiply
** Running mix loadconfig (inside Multiplier.Mixfile)
Loading from config.exs in multiplier
** Running mix multiply (inside Multiplier.Mixfile)
** Running mix deps.loadpaths (inside Multiplier.Mixfile)
** Running mix deps.precompile (inside Multiplier.Mixfile)
==> input_parser
** Running mix compile --no-deps --no-archives-check --no-elixir-version-check --no-warnings-as-errors (inside InputParser.Mixfile)
** Running mix loadpaths --no-deps --no-archives-check --no-elixir-version-check --no-warnings-as-errors (inside InputParser.Mixfile)
** Running mix compile.all --no-deps --no-archives-check --no-elixir-version-check --no-warnings-as-errors (inside InputParser.Mixfile)
** Running mix compile.yecc --no-deps --no-archives-check --no-elixir-version-check --no-warnings-as-errors (inside InputParser.Mixfile)
** Running mix compile.leex --no-deps --no-archives-check --no-elixir-version-check --no-warnings-as-errors (inside InputParser.Mixfile)
** Running mix compile.erlang --no-deps --no-archives-check --no-elixir-version-check --no-warnings-as-errors (inside InputParser.Mixfile)
** Running mix compile.elixir --no-deps --no-archives-check --no-elixir-version-check --no-warnings-as-errors (inside InputParser.Mixfile)
** Running mix compile.xref --no-deps --no-archives-check --no-elixir-version-check --no-warnings-as-errors (inside InputParser.Mixfile)
** Running mix xref warnings (inside InputParser.Mixfile)
** Running mix compile.app --no-deps --no-archives-check --no-elixir-version-check --no-warnings-as-errors (inside InputParser.Mixfile)
==> multiplier
** Running mix compile (inside Multiplier.Mixfile)
** Running mix loadpaths (inside Multiplier.Mixfile)
** Running mix archive.check (inside Multiplier.Mixfile)
** Running mix compile.all (inside Multiplier.Mixfile)
** Running mix compile.yecc (inside Multiplier.Mixfile)
** Running mix compile.leex (inside Multiplier.Mixfile)
** Running mix compile.erlang (inside Multiplier.Mixfile)
** Running mix compile.elixir (inside Multiplier.Mixfile)
** Running mix compile.xref (inside Multiplier.Mixfile)
** Running mix xref warnings (inside Multiplier.Mixfile)
** Running mix compile.app (inside Multiplier.Mixfile)
** Running mix compile.protocols (inside Multiplier.Mixfile)
** Running mix app.start (inside Multiplier.Mixfile)
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

