defmodule DockerTestService.TestRunner do
  @moduledoc """
  Запуск серии тестов (input->output) для решения в Docker.
  """

  require Logger
  alias DockerTestService.DockerRunner

  def run_tests(language, command, tests, solution_code) do
    Logger.debug("Starting test runner for language: #{language}")

    tmp_dir = create_tmp_dir()
    solution_path = Path.join(tmp_dir, "solution_file.code")
    File.write!(solution_path, solution_code)

    Logger.debug("Created temp dir: #{tmp_dir}, wrote solution code at #{solution_path}")

    results =
      Enum.with_index(tests)
      |> Enum.map(fn {test, idx} ->
        run_single_test(language, command, test, tmp_dir, idx)
      end)
      |> Enum.map(fn
        {:ok, result} -> result
        {:error, error_result} -> error_result
      end)

    cleanup_tmp_dir(tmp_dir)

    Logger.debug("Finished running tests, formatting results")

    format_results(results)
  end

  defp run_single_test(language, command, %{input: input, output: expected}, tmp_dir, idx) do
    Logger.debug("Running test ##{idx} with input: #{inspect(input)} and expected output: #{inspect(expected)}")

    try do
      stdout = DockerRunner.run_in_docker(language, command, input, tmp_dir)
      normalized_out = String.trim(stdout)
      normalized_exp = String.trim(expected)

      passed? = (normalized_out == normalized_exp)
      Logger.debug("Test ##{idx} passed: #{passed?} | Actual Output: #{inspect(normalized_out)}")

      {:ok, %{test_index: idx, input: input, expected: expected, actual: stdout, passed: passed?}}
    rescue
      e ->
        Logger.error("Error running test ##{idx}: #{Exception.message(e)}")
        {:error, %{test_index: idx, passed: false, reason: Exception.message(e)}}
    end
  end

  defp format_results(results) do
    total = length(results)
    passed_count = Enum.count(results, & &1.passed)
    summary = "Passed #{passed_count} / #{total} tests.\n\n"

    details =
      Enum.map(results, fn r ->
        if r.passed do
          "Test ##{r.test_index}: OK"
        else
          """
          Test ##{r.test_index}: FAILED
            Input: #{Map.get(r, :input, "N/A")}
            Expected: #{Map.get(r, :expected, "N/A")}
            Actual: #{Map.get(r, :actual, "N/A")}
            Reason: #{Map.get(r, :reason, "N/A")}
          """
        end
      end)
      |> Enum.join("\n")

    summary <> details
  end

  defp create_tmp_dir do
    base = System.tmp_dir!()
    unique = "docker_test_service_#{:os.system_time(:millisecond)}"
    path = Path.join(base, unique)
    File.mkdir_p!(path)
    path
  end

  defp cleanup_tmp_dir(dir), do: File.rm_rf!(dir)
end
