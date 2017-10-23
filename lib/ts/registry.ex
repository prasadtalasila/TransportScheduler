defmodule TS.Registry do
  @callback lookup_code( String.t() ) :: pid()
  @callback check_active( map() ) :: boolean()
end
