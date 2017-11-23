defmodule Room do

  @moduledoc """
  A room in the dungeon.
  """

  @enforce_keys [:rect]

  defstruct rect: nil

  @type t :: %__MODULE__{}

  @doc """
  Create a new room.

  ### Examples
      iex> Rectangle.new(2, 3, 4, 5) |> Room.new
      %Room{rect: %Rectangle{x: 2, y: 3, width: 4, height: 5}}
  """
  @spec new(Rectangle.t) :: Room.t
  def new(%Rectangle{} = rect) do
    %Room{rect: rect}
  end

  @doc """
  Checks whether two rooms overlap. A room takes more space that it's rectangle
  would indicate.

  ### Examples
      iex> room1 = Rectangle.new(2, 2, 2, 2) |> Room.new
      iex> room2 = Rectangle.new(4, 4, 2, 2) |> Room.new
      iex> Room.overlaps?(room1, room2)
      true

      iex> room1 = Rectangle.new(2, 2, 2, 2) |> Room.new
      iex> room2 = Rectangle.new(5, 4, 2, 2) |> Room.new
      iex> Room.overlaps?(room1, room2)
      true

      iex> room1 = Rectangle.new(2, 2, 2, 2) |> Room.new
      iex> room2 = Rectangle.new(10, 10, 2, 2) |> Room.new
      iex> Room.overlaps?(room1, room2)
      false
  """
  @spec overlaps?(Room.t, Room.t) :: boolean
  def overlaps?(%Room{
    rect: %Rectangle{} = rect1
  }, %Room{
    rect: %Rectangle{} = rect2
  }) do
    Rectangle.overlaps?(to_room_overlap_rect(rect1),
      to_room_overlap_rect(rect2))
    # Rectangle.overlaps?(rect1, rect2)
  end

  def to_room_overlap_rect(%Rectangle{
    x: x,
    y: y,
    width: width,
    height: height
  }) do
    %Rectangle{
      x: x - 1,
      y: y - 1,
      width: width + 1,
      height: height + 1
    }
  end

end
