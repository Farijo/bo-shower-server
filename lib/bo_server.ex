defmodule BOServer do
  @moduledoc """
  Documentation for BOServer.
  """

  @bo_file_root_path "public"
  @abs_root Path.expand(@bo_file_root_path) <> "/"

  require Logger

  def accept(port) do
    # The options below mean:
    #
    # 1. `:binary` - receives data as binaries (instead of lists)
    # 2. `packet: :line` - receives data line by line
    # 3. `active: false` - blocks on `:gen_tcp.recv/2` until data is available
    # 4. `reuseaddr: true` - allows us to reuse the address if the listener crashes
    #
    {:ok, socket} = :gen_tcp.listen(port, [:binary, packet: :line, active: false, reuseaddr: true])
    Logger.info "Accepting connections on port #{port}"
    loop_acceptor(socket)
  end

  defp loop_acceptor(socket) do
    {:ok, client} = :gen_tcp.accept(socket)
    {:ok, pid} = Task.Supervisor.start_child(BOServer.TaskSupervisor, fn -> send_list(client) end)
    :ok = :gen_tcp.controlling_process(client, pid)
    loop_acceptor(socket)
  end

  defp send_list(socket) do
    Logger.info "Connected"
    socket
    |> :gen_tcp.send(list_file(@bo_file_root_path))

    serve(socket)
  end

  defp list_file(path) do
    parse_dir(path, File.ls!(path)) ++ [int_to_binary16(0)]
  end

  defp parse_dir(_, []), do: []
  defp parse_dir(path, [file_path|queue]) do
    parse_dir(path, queue) ++ inspect_file(Path.join(path, file_path))
  end

  defp inspect_file(file_path) do
    case File.ls(file_path) do
      {:ok, subfiles} ->
        parse_dir(file_path, subfiles)
      _ ->
        get_file_couple(byte_size(file_path), file_path)
    end
  end

  defp get_file_couple(size, _) when size>255, do: []
  defp get_file_couple(size, path) do
    {:ok, {_, _, _, _, _, mtime, _, _, _, _, _, _, _, _}} = :file.read_file_info(path)
    [[<<size::size(16)>>, path, time_to_binary(mtime)]]
  end

  defp serve(socket) do
    case :gen_tcp.recv(socket, 0) do
      {:ok, xml_file} ->
        Logger.info "Requested : #{xml_file}"
        xml_file
        |> String.replace_suffix("\n", "")
        |> Path.expand
        |> send_file_requested(socket)
        serve(socket)
      _ ->
        :gen_tcp.close(socket)
    end
  end

  defp send_file_requested(filename, socket) do
    Logger.info "Checking : \n#{filename}\n#{@abs_root}"
    true = String.starts_with? filename, @abs_root
    case :file.read_file_info(filename) do
      {:ok, {_, 0, _, _, _, _, _, _, _, _, _, _, _, _}} ->
        :gen_tcp.send(socket, int_to_binary16(0))
      {:ok, {_, size, _, _, _, mtime, _, _, _, _, _, _, _, _}} ->
        :gen_tcp.send(socket, int_to_binary16(size))
        :file.sendfile(filename, socket)
        :gen_tcp.send(socket, time_to_binary(mtime))
      _ ->
        :gen_tcp.send(socket, int_to_binary16(0))
    end
  end

  defp time_to_binary(time) do
    day = time |> elem(0)
    hour = time |> elem(1)
    << day |> elem(0)::size(16),
       day |> elem(1)::size(16),
       day |> elem(2)::size(16),
       hour |> elem(0)::size(16),
       hour |> elem(1)::size(16),
       hour |> elem(2)::size(16) >>
  end

  defp int_to_binary16(value) do
    <<value::size(16)>>
  end

  def hello do
    :world
  end
end
