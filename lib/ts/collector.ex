defmodule TS.Collector do
  @callback collect( list() ) :: any()
end
