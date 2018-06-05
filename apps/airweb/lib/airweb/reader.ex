defmodule Airweb.Reader do
  require Logger

  def process_line(line, latest_tag) do
    Logger.debug ["process_line ", inspect line]
    with :ok                      <- check_line_length(line),
         :ok                      <- check_line_format(line),
         {line_content, line_tag} <- split_line(line),
         {:ok, safe_time}         <- sanitize_line(line_content) do
           build_meta(line, safe_time, line_tag, latest_tag)
    end
  end

  defp check_line_length(line) do
    Logger.debug ["check_line_length ", inspect line]
    case line |> String.trim_trailing |> String.length do
      0 -> :halt
      _ -> :ok
    end
  end

  defp check_line_format(line) do
    # TODO unbreak swap files and build
    # TODO write doctest+tests to drive out regex's
    #cond line =~ ~r/(^\w)|(^  )\w+\s+\d{2}:\d{2}/iu
    :ok
  end

  defp split_line(line) do
    case do_split line do
      [time] -> {time, :no_tag}
      [time, tag] -> {time, tag}
    end
  end

  defp do_split(line) do
    line
    |> String.split(",", [parts: 2])
    |> Enum.map(&String.trim/1)
  end

  defp sanitize_line(line) do
    case String.split line, "-" do
      [interval] -> sanitize_interval interval
      r=[_s, _e] -> sanitize_range r
    end
  end

  defp sanitize_interval(interval) do
    {:ok, {:interval, String.replace(interval, ~r/[^0-9:-]/, "")}}
  end

  defp sanitize_range(range) do
    range_extract =
      range
      |> Enum.map(&String.trim_trailing/1)
      |> Enum.map(&String.replace(&1, ~r/[^0-9:-]/, ""))
    {:ok, {:range, range_extract}}
  end

  defp compute_tag(:no_tag, latest_tag), do: latest_tag
  defp compute_tag(tag, _latest_tag), do: tag

  defp check_chunk_start(<<c::utf8, _::binary>>) when c in [?\s, ?\t], do: false
  defp check_chunk_start(_line), do: true

  defp compute_chunk_tag(_line, false), do: :no_tag
  defp compute_chunk_tag(line, true) do
    line
    |> String.split(["\s", "\t"], parts: 2)
    |> Enum.map(&String.trim/1)
    |> hd()
  end

  defp build_meta(line, safe_time, line_tag, latest_tag) do # TODO fix this
      tag         = compute_tag(line_tag, latest_tag)
      chunk_start = check_chunk_start(line)
      chunk_tag   = compute_chunk_tag(line, chunk_start)
      meta        = {safe_time, tag, chunk_start, chunk_tag}
      {:ok, meta}
  end

end

