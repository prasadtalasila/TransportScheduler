CONFIG_FILE=./home.conf

if [ -f $CONFIG_FILE ];
then
  # shellcheck disable=SC1090
  . "$CONFIG_FILE"
fi

. $USER_HOME/.asdf/asdf.sh

. $USER_HOME/.asdf/completions/asdf.bash

# erlang binaries
alias erl="$USER_HOME/.asdf/installs/erlang/20.0/bin/erl"
alias erlc="$USER_HOME/.asdf/installs/erlang/20.0/bin/erlc"
alias ct_run="$USER_HOME/.asdf/installs/erlang/20.0/bin/ct_run"
alias dialyzer="$USER_HOME/.asdf/installs/erlang/20.0/bin/dialyzer"
alias epmd="$USER_HOME/.asdf/installs/erlang/20.0/bin/epmd"
alias escript="$USER_HOME/.asdf/installs/erlang/20.0/bin/escript"
alias run_erl="$USER_HOME/.asdf/installs/erlang/20.0/bin/run_erl"
alias typer="$USER_HOME/.asdf/installs/erlang/20.0/bin/typer"

# elixir binaries
alias elixir="$USER_HOME/.asdf/installs/elixir/1.5.1/bin/elixir"
alias elixirc="$USER_HOME/.asdf/installs/elixir/1.5.1/bin/elixirc"
alias iex="$USER_HOME/.asdf/installs/elixir/1.5.1/bin/iex"
alias mix="$USER_HOME/.asdf/installs/elixir/1.5.1/bin/mix"
