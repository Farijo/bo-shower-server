defmodule BOServer.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  def start(_type, _args) do
    # List all child processes to be supervised
    children = [
      # Starts a worker by calling: BOServer.Worker.start_link(arg)
      # {BOServer.Worker, arg},
      {Task.Supervisor, name: BOServer.TaskSupervisor},
      Supervisor.child_spec({Task, fn -> BOServer.accept(4040) end}, restart: :permanent)
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: BOServer.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
