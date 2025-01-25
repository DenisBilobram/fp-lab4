defmodule DockerTestService.MixProject do
  use Mix.Project

  def project do
    [
      app: :docker_test_service,
      version: "0.1.0",
      elixir: "~> 1.13",
      start_permanent: Mix.env() == :prod,
      escript: [main_module: DockerTestService.CLI],
      deps: []
    ]
  end

  def application do
    [
      extra_applications: [:logger],
      mod: {DockerTestService.Application, []}
    ]
  end
end
