require Logger
defmodule RTreeServer do
	use GenServer
	def start_link do
		Logger.info "init"
		GenServer.start_link(__MODULE__,{HashDict.new,:rstar.new(2)},name: :rtree)
	end
	def store(uid,geo) do
		GenServer.cast(:rtree,{:store,uid,geo})
	end
	def position(uid) do
		GenServer.call(:rtree,{:position,uid})
	end
	def neighbor(uid,distance) do 
		GenServer.call(:rtree,{:neighbor,uid,distance})
	end
	def handle_cast({:store,uid,geo},{dict,rtree}) do
		if HashDict.has_key?(dict,uid) do
			oldp = dict[uid]
			rtree = :rstar.delete(rtree,oldp)
		end
		{:noreply,{Dict.put(dict,uid,geo),:rstar.insert(rtree,geo)}}
	end
	def handle_call({:position,uid},_from,{dict,rtree}) do
		geo = dict[uid]
		{:reply,{dict[uid],:rstar.search_around(rtree,geo,8)},{dict,rtree}}
	end
	def handle_call({:neighbor,uid,distance},_from,{dict,rtree}) do
		geo = dict[uid]
		{:reply,{dict[uid],:rstar.search_around(rtree,geo,distance)},{dict,rtree}}
	end

end
defmodule RTest do
	use Application
	def genpoint(uid,dist) do
		x = :random.uniform(dist) - (div dist,2)
		y = :random.uniform(dist) - (div dist,2)
		geo = :rstar_geometry.new(2,[{x,x+1},{y,y+1}],uid)
		RTreeServer.store(uid,geo)
	end
	def getpoint(uid) do
		{curr,near} = RTreeServer.position(uid)
		sz = Enum.count(near)
		IO.puts "uid=#{uid} sz=#{sz}"
	end
	def main do
		RTreeServer.start_link
		1..1000 |> Enum.map(&(RTest.genpoint &1,50))
		1..1000 |> Enum.map(&(RTest.getpoint &1))
		1..1000 |> Enum.map(&(RTest.genpoint &1,50))
		1..1000 |> Enum.map(&(RTest.getpoint &1))
	end
end
