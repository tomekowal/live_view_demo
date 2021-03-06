defmodule LiveViewDemoWeb.GameLive do
  use Phoenix.LiveView
  alias LiveViewDemo.Games

  defmodule PlayerInput do
    defstruct [:guessed_number]
  end

  def render(assigns) do
    ~L"""
    <div phx-keydown="keypress" phx-target="window" class="page">
      <div class="timer-container">
        <%= timer(@remaining_time) %>
      </div>
      <div style="text-align: center; font-size: 2em; width: 100%;">
        Score: <%= @score %>
      </div>
      <div style="text-align: center; font-size: 2em; width: 100%;">
        <%= @puzzle %>
      </div>
      <div class="guess">
        <p><%= @guess %>&nbsp;</p>
      </div>
      <div class="keypad">
        <%= keypad(@remaining_time) %>
      </div>
    </div>
    """
  end

  defp timer(remaining_time) do
    if remaining_time == 0 do
      {:safe,
       """
       <div class="game-over">Game Over</div>
       """}
    else
      {:safe,
       """
       <div class="timer" style="width: #{remaining_time * 27}px;"></div>
       """}
    end
  end

  defp keypad(remaining_time) do
    {:safe,
     [
       Enum.map(1..9, &key(&1, remaining_time)),
       empty(),
       key(0, remaining_time),
       clear_button(remaining_time)
     ]}
  end

  defp key(digit, remaining_time) do
    disabled = if remaining_time == 0, do: "disabled", else: ""

    """
    <div onclick="" class="key #{disabled}" phx-click="keyclick" phx-value-button="#{digit}">
      #{digit}
    </div>
    """
  end

  defp empty do
    """
    <div class="key"></div>
    """
  end

  defp clear_button(remaining_time) do
    text = if remaining_time == 0, do: "Again!", else: "Clear"

    """
    <div onclick="" class="key" phx-click="keyclick" phx-value-button="clear">#{text}<br />(Space)</div>
    """
  end

  def mount(_session, socket) do
    socket =
      socket
      |> maybe_start_game()
      |> assign(%{remaining_time: 0, puzzle: "", guess: "", score: 0})

    {:ok, socket}
  end

  defp maybe_start_game(socket) do
    if connected?(socket) do
      {:ok, game_handle} = Games.new(update_fn())

      socket
      |> assign(%{
        game_handle: game_handle
      })
    else
      socket
    end
  end

  defp update_fn() do
    live_view_process = self()
    fn game -> send(live_view_process, {:tick, game}) end
  end

  def handle_event("keypress", key, socket) do
    pressed_key = key["key"]
    parse_result = Integer.parse(pressed_key)

    cond do
      pressed_key == " " ->
        clear(socket)

      :error == parse_result ->
        noreply(socket)

      {_integer, ""} = parse_result ->
        digit(pressed_key, socket)
    end
  end

  def handle_event("keyclick", key_press, socket) do
    button = key_press["button"]

    case button do
      "clear" ->
        clear(socket)

      button ->
        digit(button, socket)
    end
  end

  def handle_info({:tick, game_state}, socket) do
    socket
    |> assign(game_state)
    |> noreply()
  end

  defp digit(pressed_key, socket) do
    game_state = Games.player_input(socket.assigns.game_handle, pressed_key)

    socket
    |> assign(game_state)
    |> noreply()
  end

  defp clear(socket) do
    game_state = Games.clear(socket.assigns.game_handle)

    socket
    |> assign(game_state)
    |> noreply()
  end

  defp noreply(socket), do: {:noreply, socket}
end
