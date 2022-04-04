defmodule Pencil.Discord.Command.Parser.Helpers do
  import NimbleParsec

  def word do
    repeat_while(utf8_char([]), {:until_not_ch, [?\s]}) |> reduce({List, :to_string, []})
  end

  def string do
    ignore(ascii_char([?"]))
    |> repeat_while(
      choice([
        ~S(\") |> string() |> replace(?"),
        utf8_char([])
      ]),
      {__MODULE__, :until_not_ch, [?"]}
    )
    |> ignore(ascii_char([?"]))
    |> reduce({List, :to_string, []})
  end

  def until_not_ch(<<ch, _::binary>>, context, _, _, not_ch) when ch == not_ch,
    do: {:halt, context}

  def until_not_ch(_, context, _, _, _), do: {:cont, context}
end

defmodule Pencil.Discord.Command.Parser do
  import NimbleParsec
  import Pencil.Discord.Command.Parser.Helpers

  @prefix Application.compile_env!(:pencil_discord, [:bot, :prefix])

  parse_prefix =
    choice([
      ignore(string(@prefix)),
      ignore(string("<@!"))
      |> post_traverse(integer(min: 1), {:validate_prefix_id, []})
      |> ignore(string(">"))
      |> optional(ignore(string(" ")))
    ])

  defp validate_prefix_id(rest, [uid], context, _line, _offset) do
    if uid == Nostrum.Cache.Me.get().id do
      {rest, [], context}
    else
      {:error, "Invalid prefix id #{uid}"}
    end
  end

  defparsec(:prefix, parse_prefix)
  defparsec(:command, concat(parse_prefix, unwrap_and_tag(word(), :cmd_name)))
end
