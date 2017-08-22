defmodule SB do
  def loop(pid, str) do
    data = Registry.lookup(pid, str)
    loop(pid, str)
  end

  def driver(pid, str) do
    Registry.addProcess(pid, self() )
    loop(pid, str)
  end

  def runner(n, str) do
    {:ok, pid} = Registry.start_link
    spawner(n, str, pid)
    Registry.start_timer(pid)
    :timer.sleep(31_000)
    val = Registry.getCount(pid)
    Registry.stop(pid)
    IO.puts "for #{n} processes sending messages of size #{byte_size(str)} : #{val}"
  end

  def spawner(n, str, pid) when n > 0 do
    spawn(SB,:driver,[pid, str])
    spawner(n-1, str, pid)
  end

  def spawner(n, str, pid) do
  end
end
