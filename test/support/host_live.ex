defmodule PhoenixKitBoards.Test.HostLive do
  @moduledoc """
  A page that embeds the panel the way a host app would, taking everything it
  needs from the test's session: the signed-in user's uuid and the panel's
  options.
  """
  use Phoenix.LiveView

  alias PhoenixKitBoards.Test.Repo

  @impl true
  def mount(_params, session, socket) do
    # What core's on_mount does for the process: the locale of the request.
    if locale = session["locale"], do: Gettext.put_locale(locale)

    user =
      case session["user_uuid"] do
        nil -> nil
        uuid -> Repo.get(PhoenixKit.Users.Auth.User, uuid)
      end

    {:ok, assign(socket, user: user, opts: session["opts"] || [])}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <main>
      <PhoenixKitBoards.Web.Components.boards_panel
        id="panel"
        current_user={@user}
        {Map.new(@opts)}
      />
    </main>
    """
  end
end
