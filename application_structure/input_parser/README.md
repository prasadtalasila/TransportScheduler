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

EXPECTED OUTPUT-
```
$ bash script/normal_parse.sh 
Loading from config/config.exs in input parser
Resolving Hex dependencies...
Dependency resolution completed:
  logger_file_backend 0.0.10
All dependencies up to date
Loading from config/config.exs in input parser
Starting application in InputParser.Application(lib/input_parser/application.ex)
Input Parser Initialised and Queries are Obtained
Qmap is %{1 => 2, 3 => 4, 5 => 6}
```

2. For running in debug mode-

run `bash script/debug.sh`

and check `log/debug.log`

EXPECTED OUTPUT-

```
$ bash script/debug.sh
Loading from config/config.exs in input parser
Resolving Hex dependencies...
Dependency resolution completed:
  logger_file_backend 0.0.10
All dependencies up to date
Loading from config/config.exs in input parser
using debug config file
Starting application in InputParser.Application(lib/input_parser/application.ex)
Input Parser Initialised and Queries are Obtained
```


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

