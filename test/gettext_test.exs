defmodule PhoenixKitBoards.GettextTest do
  @moduledoc """
  The module ships Russian and Estonian. These hold each translation to the same
  standard as the English source, so a string added later cannot slip out
  untranslated, or with a placeholder the translator dropped.
  """
  use ExUnit.Case, async: true

  alias PhoenixKit.Dashboard.Tab

  @locales ~w(ru et)
  @pot Path.expand("../priv/gettext/default.pot", __DIR__)
  @lib Path.expand("../lib", __DIR__)

  # {msgid, msgstr, flags} for each real entry of a .po/.pot file.
  defp entries(path) do
    path
    |> File.read!()
    |> String.split(~r/\n\n+/, trim: true)
    |> Enum.flat_map(fn block ->
      with [_, id] <- Regex.run(~r/^msgid "((?:[^"\\]|\\.)*)"$/m, block),
           true <- id != "",
           [_, str] <- Regex.run(~r/^msgstr "((?:[^"\\]|\\.)*)"$/m, block) do
        [{id, str, block}]
      else
        _ -> []
      end
    end)
  end

  defp placeholders(text),
    do: ~r/%\{(\w+)\}/ |> Regex.scan(text) |> Enum.map(&List.last/1) |> Enum.sort()

  defp po(locale), do: Path.expand("../priv/gettext/#{locale}/LC_MESSAGES/default.po", __DIR__)

  test "the catalog has the strings the code asks for, and nothing stale" do
    # Every literal handed to gettext in the source, found by reading it — so a
    # string wrapped but never extracted (or an extracted one since removed)
    # fails here, with its name, instead of shipping in English.
    in_code =
      Path.wildcard(Path.join(@lib, "**/*.ex"))
      |> Enum.flat_map(fn file ->
        src = File.read!(file)

        Regex.scan(~r/\bgettext\(\s*"((?:[^"\\]|\\.)*)"/, src, capture: :all_but_first)
        |> Kernel.++(
          Regex.scan(~r/\bdgettext_noop\(\s*"default",\s*"((?:[^"\\]|\\.)*)"/, src,
            capture: :all_but_first
          )
        )
        |> List.flatten()
      end)
      |> MapSet.new()

    in_pot = @pot |> entries() |> Enum.map(&elem(&1, 0)) |> MapSet.new()

    assert MapSet.to_list(MapSet.difference(in_code, in_pot)) == [],
           "wrapped in the code but not in priv/gettext/default.pot — run `mix gettext.extract --merge`"

    assert MapSet.to_list(MapSet.difference(in_pot, in_code)) == [],
           "in the catalog but no longer in the code — run `mix gettext.extract --merge`"
  end

  for locale <- @locales do
    describe "#{locale}" do
      test "every message is translated" do
        untranslated = for {id, "", _} <- entries(po(unquote(locale))), do: id
        assert untranslated == [], "untranslated in #{unquote(locale)}: #{inspect(untranslated)}"
      end

      test "no translation is left marked fuzzy" do
        fuzzy =
          for {id, _, block} <- entries(po(unquote(locale))), block =~ ~r/^#,.*\bfuzzy\b/m, do: id

        assert fuzzy == [], "fuzzy in #{unquote(locale)}: #{inspect(fuzzy)}"
      end

      test "every translation keeps its placeholders" do
        broken =
          for {id, str, _} <- entries(po(unquote(locale))),
              placeholders(id) != placeholders(str),
              do: {id, str}

        assert broken == [], "placeholders changed in #{unquote(locale)}: #{inspect(broken)}"
      end

      test "the catalog has exactly the .pot's messages" do
        ids = @pot |> entries() |> Enum.map(&elem(&1, 0)) |> Enum.sort()
        assert po(unquote(locale)) |> entries() |> Enum.map(&elem(&1, 0)) |> Enum.sort() == ids
      end
    end
  end

  describe "the sidebar tab" do
    test "is translated by core through the tab's own backend" do
      [tab] = PhoenixKitBoards.admin_tabs()

      assert tab.gettext_backend == PhoenixKitBoards.Gettext

      assert Gettext.with_locale(PhoenixKitBoards.Gettext, "en", fn ->
               Tab.localized_label(tab)
             end) == "Boards"

      assert Gettext.with_locale(PhoenixKitBoards.Gettext, "ru", fn ->
               Tab.localized_label(tab)
             end) == "Доски"

      assert Gettext.with_locale(PhoenixKitBoards.Gettext, "et", fn ->
               Tab.localized_label(tab)
             end) == "Tahvlid"
    end
  end
end
