defmodule Airweb.Reader do
  alias Airweb.ReaderEntry, as: ReaderEntry

  require Logger

  # lexing rules
  @chunk_re "(?<chunk>^\\w+)"
  @time_re "(?<time>\\d{2}:\\d{2}(-\\d{2}:\\d{2})?)"
  @tag_re "(?<tag>\\S.*)"
  @tag_separator_re "((,\\s*)|\\s+)"

  @lex_re ~r/(#{@chunk_re}\s+)?(#{@time_re}(,?\s*#{@tag_re})?)$/iu
  @line_chunk_start_re ~r/#{@chunk_re}\s+#{@time_re}#{@tag_separator_re}#{@tag_re}/iu
  @line_chunk_append_re ~r/^\s+#{@time_re}(#{@tag_separator_re}\S.*)?$/iu

  @doc ~S"""
  Parses a timesheet item expected to contain the following parts:

  [chunk-tag] [range-or-interval][[,|\s+]line-tag]

      iex> Reader.process_line("Må 08:15-11:45, Bar")
      {:ok, %Airweb.ReaderEntry{
              chunk: "Må",
              tag: "Bar",
              time: {:range, ["08:15", "11:45"]},
              type: :start
            }}

      iex> Reader.process_line("  10:30-14:15")
      {:ok, %Airweb.ReaderEntry{
              chunk: :no_chunk,
              tag: :no_tag,
              time: {:range, ["10:30", "14:15"]},
              type: :append
            }}

      iex> Reader.process_line("  14:00 Foo")
      {:ok, %Airweb.ReaderEntry{
              chunk: :no_chunk,
              tag: "Foo",
              time: {:interval, "14:00"},
              type: :append
            }}

  """
  def process_line(dirty_line) do
    Logger.debug(["process_line dirty:", inspect(dirty_line)])
    line = String.trim_trailing(dirty_line)
    Logger.debug(["process_line clean:", inspect(line)])

    with :ok <- check_line_length(line),
         {:ok, line_type} <- check_line_type(line) do
      tokens = lex_line(line)
      {:ok, ReaderEntry.create_entry(tokens, line_type)}
    else
      :halt ->
        :halt

      err = {:error, reason} ->
        Logger.warn([
          "Input error: ",
          inspect(reason),
          " (",
          inspect(dirty_line),
          ")"
        ])

        err
    end
  end

  # TODO change to :skip and handle downstream
  defp check_line_length(""), do: :halt
  defp check_line_length(_), do: :ok

  defp check_line_type(line) do
    cond do
      line =~ @line_chunk_start_re -> {:ok, :start}
      line =~ @line_chunk_append_re -> {:ok, :append}
      true -> {:error, {:bad_format, line}}
    end
  end

  defp lex_line(line) do
    Regex.named_captures(@lex_re, line)
  end

end
