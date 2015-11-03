require Logger

defmodule TestMe do
  use Application

  # See http://elixir-lang.org/docs/stable/elixir/Application.html
  # for more information on OTP Applications
  def start(_type, _args) do
    import Supervisor.Spec, warn: false

    children = [
      # Define workers and child supervisors to be supervised
      # worker(TestMe.Worker, [arg1, arg2, arg3])
			worker(TestMe.Worker, []),
			worker(RTreeServer,[]),
			worker(UserProxy,[])

    ]

    # See http://elixir-lang.org/docs/stable/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: TestMe.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
defmodule TestMe.Worker do
  def start_link do
		Logger.info "test me worker start"
    opts = [port: 8000]
    {:ok, _} = :ranch.start_listener(:Testme, 1000, :ranch_tcp, opts, TestMe.Handler, [])
  end
end
defmodule TestMe.Handler do
  def start_link(ref, socket, transport, opts) do
    pid = spawn_link(__MODULE__, :init, [ref, socket, transport, opts])
    {:ok, pid}
  end
  def init(ref, socket, transport, _Opts = []) do
    :ok = :ranch.accept_ack(ref)
		sz = :ranch_server.count_connections(ref)
		Logger.info "connect :ok size=#{sz}"
    loop(ref,socket, transport)
  end
	
  def loop(ref,socket, transport) do
		receive do
			{:send,data}->
				transport.send(socket,data)
				loop(ref,socket,transport)
		end
    case transport.recv(socket, 0, 50_000) do
      {:ok, data} ->
				sz = :ranch_server.count_connections(ref)
				{:ok,pdata} = MessagePack.unpack(data)
				i = Enum.at(pdata,0)
				p = Enum.at(pdata,2)
				if (rem i,100) == 0 and (rem p,100) == 0 do
 					Logger.info ":ok sz=#{sz} i=#{i} p=#{p}"
				end
        transport.send(socket, data)
        loop(ref,socket, transport)
      {:error, :closed} ->
				Logger.info "closed"
        :ok = transport.close(socket)
      {:error, :timeout} ->
				Logger.info "timeout"
        :ok = transport.close(socket)
      {:error, _} -> # err_message
				Logger.info "unknown"
        :ok = transport.close(socket)
      _ ->
				Logger.info "unknown"
        :ok = transport.close(socket)
    end
		#Logger.info "out close"
		#:ok = transport.close(socket)
  end
end
