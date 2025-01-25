defmodule DockerTestService.CLI do
  @moduledoc """
  CLI для запуска приложения из Mix (или напрямую через elixir).
  """

  def main(_args) do

    Logger.configure(level: :debug)

    DockerTestService.Application.start(:normal, [])

    Process.sleep(:infinity)
  end
end
