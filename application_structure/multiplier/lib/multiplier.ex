defmodule Multiplier do
  
    
        use GenServer
    
        def start_link(_) do
                GenServer.start_link(__MODULE__,:ok, [debug: [:statistics, :trace]])
        end

    
        def write_products(pid) do
                GenServer.call(pid,:write_products)
        end


        def init(:ok) do
                IO.puts "Multiplier initialised"
                list=[]              
                {:ok,list}
        end

        def handle_call(:write_products,_from,list) do


                [tuple]=Supervisor.which_children(InputParser.Supervisor)
                pid=elem(tuple,1)
                calculate(pid)
                {:reply,list,list}
        end    
        
    
        def calculate(pid) do
                    
                IO.puts "Multiplying...."
                qmap=InputParser.get_query_map(pid)

                Enum.each(qmap,fn{k,v} -> 

                        res=k*v           
                        {:ok, file} = File.open "results.txt", [:append]
                        IO.binwrite file, "#{k} * #{v} = #{res} \n"

                end
                )

                IO.puts "Done calculating,please open results.txt"

        end

        def get_pid do
            self()
        end





end
