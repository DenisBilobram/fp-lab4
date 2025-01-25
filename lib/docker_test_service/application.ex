defmodule DockerTestService.Application do
  @moduledoc """
  Главный модуль приложения, который поднимает сервер при старте.
  """
  use Application

  def start(_type, _args) do
    children = [
      {DockerTestService.Server, 4000}
    ]

    opts = [strategy: :one_for_one, name: DockerTestService.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
