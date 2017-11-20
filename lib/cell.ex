defmodule Cell do

  @moduledoc """
  An individual cell on a map grid.
  """

  require Bitwise

  @enforce_keys [:x, :y, :val]

  defstruct x: nil,
    y: nil,
    val: nil

  @type t :: %__MODULE__{}

  @in_room 16
  @open_north 1
  @open_south 2
  @open_east 4
  @open_west 8

  @doc """
  Create a new cell with a given X and Y coordinate.

  ### Examples

      iex> Cell.new(1, 2)
      %Cell{x: 1, y: 2, val: 0}
  """
  @spec new(integer, integer) :: Cell.t
  def new(x, y) do
    %Cell{x: x, y: y , val: 0}
  end

  @doc """
  Sets a cell to be in a room.

  ### Examples

      iex> Cell.new(1, 2) |> Cell.in_room
      %Cell{x: 1, y: 2, val: 16}

      iex> Cell.new(1, 2) |> Cell.open(:north) |> Cell.in_room
      %Cell{x: 1, y: 2, val: 17}
  """
  @spec in_room(Cell.t) :: Cell.t
  def in_room(%Cell{val: val} = cell) do
    %{cell | val: Bitwise.bor(val, @in_room)}
  end

  @doc """
  Checks if a cell is in a room.

  ### Examples

      iex> Cell.new(1, 2) |> Cell.in_room?
      false

      iex> Cell.new(1, 2) |> Cell.in_room |> Cell.in_room?
      true
  """
  @spec in_room?(Cell.t) :: boolean
  def in_room?(%Cell{val: val}) do
    @in_room == Bitwise.band(val, @in_room)
  end

  @doc """
  Checks if the cell is within a grid area.

  ### Examples

      iex> Cell.new(1, 3) |> Cell.within?(%Rectangle{x: 1, y: 1, height: 1, width: 2})
      true

      iex> Cell.new(1, 3) |> Cell.within?(%Rectangle{x: 1, y: 1, height: 1, width: 1})
      false

      iex> Cell.new(2, 2) |> Cell.within?(%Circle{x: 3, y: 3, radius: 3})
      true

      iex> Cell.new(2, 2) |> Cell.within?(%Circle{x: 3, y: 3, radius: 2})
      false

      iex> Cell.new(2, 2) |> Cell.within?(%Circle{x: 3, y: 3, radius: 1})
      false
  """
  @spec within?(Cell.t, Rectangle.t) :: boolean
  def within?(%Cell{x: cx, y: cy}, %Rectangle{} = rect) do
    Rectangle.within?(rect, {cx, cy})
  end

  def within?(%Cell{x: cx, y: cy}, %Circle{} = circle) do
    Circle.within?(circle, {cx, cy})
  end

  @doc """
  Open cell to the north.

  ### Examples

      iex> Cell.open(Cell.new(1, 2), :north)
      %Cell{x: 1, y: 2, val: 1}

      iex> Cell.new(1, 2) |> Cell.open(:north) |> Cell.open(:west)
      %Cell{x: 1, y: 2, val: 9}

      iex> Cell.new(1, 2) |> Cell.open(:north) |> Cell.open(:south)
      %Cell{x: 1, y: 2, val: 3}
  """
  @spec open(Cell.t, :north | :south | :east | :west) :: Cell.t
  def open(%Cell{val: val} = cell, :north) do
    %{cell | val: Bitwise.bor(val, @open_north)}
  end

  def open(%Cell{val: val} = cell, :south) do
    %{cell | val: Bitwise.bor(val, @open_south)}
  end

  def open(%Cell{val: val} = cell, :east) do
    %{cell | val: Bitwise.bor(val, @open_east)}
  end

  def open(%Cell{val: val} = cell, :west) do
    %{cell | val: Bitwise.bor(val, @open_west)}
  end

end
