defmodule PhoenixKitBoards.Gettext do
  @moduledoc """
  Gettext backend for the boards module's own translations.

  Every LiveView, the widget and the module's tab labels resolve against **this**
  package's catalogs (`priv/gettext`), so the translations ship with the module
  and are extracted and merged with the module's own `mix gettext.extract --merge`.
  English is the source language; Russian (`ru`) and Estonian (`et`) are
  translated. The locale is the one core puts on the process for the request, so
  a widget embedded in a host page follows the host's language.

  Add a language by running `mix gettext.merge priv/gettext --locale <code>` and
  translating the new `priv/gettext/<code>/LC_MESSAGES/default.po`; the
  completeness test (`test/gettext_test.exs`) then holds it to the same standard.
  """
  use Gettext.Backend, otp_app: :phoenix_kit_boards
end
