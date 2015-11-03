require Logger

defmodule UserProxy do
	use GenServer
	def start_link do
		Logger.info "user proxy start"
		GenServer.start_link(__MODULE__,{HashDict.new},name: :user_proxy)
	end
	def store(uid,pid) do
		GenServer.cast(:user_proxy,{:store,uid,pid})
	end
	def say(uid,data) do
		#Genserver.call(:user_proxy,{:say,uid,data})
		GenServer.cast(:user_proxy,{:sey,uid,data})
	end
	def handle_cast({:store,uid,pid},dict) do
		{:noreply,{Dict.put(dict,uid,pid)}}
	end
	def handle_cast({:say,uid,data},dict) do
		Enum.map(dict,fn {k,v}  -> 
			send v,{:send,data}
		end)
		{:noreply,dict}
	end
	#def handle_call({:say,uid,data},_from,dict) do
		#{:}
	#end
end
