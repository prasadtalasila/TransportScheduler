defmodule InputParser do
        
        
        use GenServer

        def start_link(_) do
                GenServer.start_link(__MODULE__, :ok)
        end

        def get_query_map(pid) do
                GenServer.call(pid, :get_query_map)
        end

        def init(:ok) do
                qmap=obtain_queries()
                IO.puts"Input Parser Initialised and Queries are Obtained"
                {:ok,qmap}
        end

        def handle_call(:get_query_map, _from,qmap) do

                {:reply, qmap,qmap}
        end
        

        def obtain_queries do
                query_map=Map.new
                {_,file}=open_file("queries.txt")
                n=3
                obtain_query(file,n,query_map)

        end

        def obtain_query(file,n,query_map) when n>0 do

                [num,pow]=file|>IO.binread(:line)|>String.trim()|>String.split(" ",parts: 2)
                num=String.to_integer(num)
                pow=String.to_integer(pow)
                
                #IO.puts("Num1 is #{num},power is #{pow}")
                query_map=Map.put(query_map,num,pow)
 
                obtain_query(file,n-1,query_map)

                
        end

        def obtain_query(_,n,map) when n<=0 do
                map

        end

        defp open_file(filename) do
                File.open(filename, [:read, :binary])
        end
        

end
