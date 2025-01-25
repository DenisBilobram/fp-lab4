defmodule DockerTestService.Server do
  @moduledoc """
  TCP-сервер, который принимает данные о тестах и решении, запускает их в Docker
  и возвращает результат.
  """
  use GenServer

  require Logger

  def start_link(port) when is_integer(port) do
    GenServer.start_link(__MODULE__, port, name: __MODULE__)
  end

  @impl true
  def init(port) do
    {:ok, listen_socket} =
      :gen_tcp.listen(port, [:binary, packet: :line, active: false, reuseaddr: true])

    Logger.info("Server started on port #{port}")
    spawn_link(fn -> accept_loop(listen_socket) end)

    {:ok, %{port: port, listen_socket: listen_socket}}
  end

  defp accept_loop(listen_socket) do
    {:ok, client_socket} = :gen_tcp.accept(listen_socket)
    spawn(fn -> handle_client(client_socket) end)
    accept_loop(listen_socket)
  end

  defp handle_client(socket) do
    :gen_tcp.send(socket, "Welcome to Docker Test Service!\n")
    Logger.info("Client connected: #{inspect(socket)}")

    case read_request(socket) do
      {:ok, %{language: lang, command: cmd, tests: tests, code: solution_code}} ->
        Logger.info("Received request: Language=#{lang}, Command=#{cmd}, Tests=#{length(tests)}")

        results_str = DockerTestService.TestRunner.run_tests(lang, cmd, tests, solution_code)

        :gen_tcp.send(socket, "RESULT_START\n")
        :gen_tcp.send(socket, results_str <> "\n")
        :gen_tcp.send(socket, "RESULT_END\n")

      {:error, reason} ->
        Logger.error("Error processing client request: #{inspect(reason)}")
        :gen_tcp.send(socket, "ERROR: #{inspect(reason)}\n")
    end

    Logger.info("Client disconnected: #{inspect(socket)}")
    :gen_tcp.close(socket)
  end

  @doc """
  Чтение всего запроса от клиента:

  Ожидается формат (каждая строка завершается переводом строки):

      LANGUAGE:<docker_image>
      COMMAND:<command>

      TEST_START
      INPUT:...
      OUTPUT:...
      INPUT:...
      OUTPUT:...
      ...
      TEST_END

      CODE_START
      ...
      CODE_END
  """
  def read_request(socket) do
    with {:ok, lang_line}    <- read_line(socket),
         {:ok, language}     <- parse_prefixed_line(lang_line, "LANGUAGE:"),
         {:ok, cmd_line}     <- read_line(socket),
         {:ok, command}      <- parse_prefixed_line(cmd_line, "COMMAND:"),
         {:ok, tests}        <- read_tests_block(socket),
         {:ok, solution}     <- read_code_block(socket)
    do
      {:ok, %{language: language, command: command, tests: tests, code: solution}}
    else
      error -> error
    end
  end

  defp read_tests_block(socket) do
    case read_line(socket) do
      {:ok, "TEST_START"} ->
        Logger.info("TEST_START found")
        tests = collect_tests(socket, [])
        {:ok, tests}

      other ->
        Logger.error("Expected TEST_START, got: #{inspect(other)}")
        {:error, :test_block_not_found}
    end
  end

  defp collect_tests(socket, acc) do
    case read_line(socket) do
      {:ok, "TEST_END"} ->
        Logger.info("TEST_END found")
        Enum.reverse(acc)

      {:ok, line} ->
        if String.starts_with?(line, "INPUT:") do
          input_val = String.trim_leading(line, "INPUT:") |> String.trim()
          Logger.debug("Parsed INPUT: #{inspect(input_val)}")

          case read_line(socket) do
            {:ok, out_line} ->
              if String.starts_with?(out_line, "OUTPUT:") do
                output_val = String.trim_leading(out_line, "OUTPUT:") |> String.trim()
                Logger.debug("Parsed OUTPUT: #{inspect(output_val)}")

                new_test = %{input: input_val, output: output_val}
                collect_tests(socket, [new_test | acc])
              else
                {:error, :output_not_found}
              end

            {:error, _} = err ->
              err
          end
        else
          {:error, :invalid_test_format}
        end

      {:error, _} = err ->
        err
    end
  end

  defp read_code_block(socket) do
    case read_line(socket) do
      {:ok, "CODE_START"} ->
        Logger.info("CODE_START found")
        code = collect_code_until_end(socket, [])
        {:ok, code}

      other ->
        Logger.error("Expected CODE_START, got: #{inspect(other)}")
        {:error, :code_block_not_found}
    end
  end

  defp collect_code_until_end(socket, acc) do
    case read_line(socket) do
      {:ok, "CODE_END"} ->
        Logger.info("CODE_END found")
        Enum.reverse(acc) |> Enum.join("\n")

      {:ok, line} ->
        collect_code_until_end(socket, [line | acc])

      {:error, _} ->
        Enum.reverse(acc) |> Enum.join("\n")
    end
  end

  defp read_line(socket) do
    case :gen_tcp.recv(socket, 0) do
      {:ok, data} ->
        line = String.trim(data)
        Logger.debug("Received line: #{inspect(line)}")
        {:ok, line}

      {:error, reason} ->
        Logger.error("Error reading line: #{inspect(reason)}")
        {:error, reason}
    end
  end

  defp parse_prefixed_line(line, prefix) do
    if String.starts_with?(line, prefix) do
      val = String.trim_leading(line, prefix) |> String.trim()
      {:ok, val}
    else
      {:error, :invalid_prefix}
    end
  end
end
