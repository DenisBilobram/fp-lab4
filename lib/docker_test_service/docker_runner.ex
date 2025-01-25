defmodule DockerTestService.DockerRunner do
  @moduledoc """
  Модуль для запуска Docker-контейнера с решением.
  """

  require Logger

  def run_in_docker(image, command, input, tmp_dir) do
    docker_path = convert_windows_path_to_docker(tmp_dir)

    input_file = Path.join(tmp_dir, "input.txt")
    File.write!(input_file, input)
    Logger.debug("Written input to file: #{input_file}")

    shell_command = "cat /app/input.txt | #{command}"

    docker_args = [
      "run",
      "--rm",
      "-i",
      "-v",
      "#{docker_path}:/app",
      "-w",
      "/app",
      image,
      "sh",
      "-c",
      shell_command
    ]

    Logger.debug("Running Docker: docker #{Enum.join(docker_args, " ")}")

    {output, exit_code} =
      try do
        System.cmd("docker", docker_args, stderr_to_stdout: true)
      rescue
        e in ErlangError ->
          if e.original == :enoent do
            Logger.error("Docker command not found")
            raise "Docker command not found"
          else
            raise e
          end
      end

    Logger.debug("Docker output: #{inspect(output)}")
    Logger.debug("Docker exit code: #{inspect(exit_code)}")

    File.rm!(input_file)

    if exit_code != 0 do
      Logger.error("Docker command failed with exit code #{exit_code}")
      raise "Docker command failed: #{output}"
    end

    output
  end

  defp convert_windows_path_to_docker(path) do
    Logger.debug("Original path: #{path}")

    if String.match?(path, ~r/^[A-Za-z]:[\/\\]/) do
      drive_letter = String.at(path, 0) |> String.downcase()
      rest = String.slice(path, 2..-1//1) |> String.replace(~r/[\/\\]/, "/")
      docker_path = "/#{drive_letter}/#{rest}"
      Logger.debug("Converted path to Docker format: #{docker_path}")
      docker_path
    else
      Logger.debug("Non-Windows path, no conversion needed")
      path
    end
  end
end
