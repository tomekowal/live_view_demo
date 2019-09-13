defmodule LiveViewDemo.Games.Model.Game do
  defstruct [:remaining_time, :puzzle, :score]

  alias LiveViewDemo.Games.Model.{Game, Puzzle, Guess}

  @opaque t :: %__MODULE__{
            remaining_time: non_neg_integer(),
            puzzle: Puzzle.t(),
            score: non_neg_integer()
          }

  @spec new(:rand.seed_state()) :: {:ok, t()} | {:error, any()}
  def new(seed_state) do
    case Puzzle.new(seed_state) do
      {:ok, puzzle} ->
        {:ok,
         %Game{
           puzzle: puzzle,
           remaining_time: 10
         }}

      {:error, _} = error ->
        error
    end
  end

  @spec guess(t(), Guess.t()) :: {:correct, t()} | {:incorrect, t()}
  def guess(game, guess) do
    case Puzzle.correct?(game.puzzle, Guess.to_integer(guess)) do
      true ->
        {:ok, next_puzzle} = Puzzle.next(game.puzzle)

        {:correct,
         %{
           game
           | remaining_time: game.remaining_time + 1,
             puzzle: next_puzzle
         }}

      false ->
        {:incorrect, game}
    end
  end

  @spec tick(t()) :: {:continue, t()} | {:stop, t()}
  def tick(%Game{remaining_time: 0} = game) do
    {:stop, game}
  end

  def tick(%Game{remaining_time: time} = game) when time > 0 do
    {:continue, %Game{game | remaining_time: time - 1}}
  end

  @spec to_map(t()) :: map()
  def to_map(game) do
    game
    |> Map.from_struct()
    |> Map.update!(:puzzle, &Puzzle.to_string/1)
    |> Map.take([:remaining_time, :puzzle, :score])
  end
end
