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
      iex> room2 = Rectangle.new(6, 4, 2, 2) |> Room.new
      iex> Room.overlaps?(room1, room2)
      false
  """
  @spec overlaps?(Room.t, Room.t) :: boolean
  def overlaps?(%Room{
    rect: %Rectangle{
      x: x,
      y: y,
      width: width,
      height: height
    }
  }, %Room{
    rect: %Rectangle{
      x: other_x,
      y: other_y,
      width: other_width,
      height: other_height
    }
  }) do
    not(((x + width + 2) < other_x) or
      ((other_x + other_width + 2) < x) or
      ((y + height + 2) < other_y) or
      ((other_y + other_height + 2) < y))
    # Rectangle.overlaps?(to_room_overlap_rect(rect1),
    #   to_room_overlap_rect(rect2))
  end

  defp to_room_overlap_rect(%Rectangle{
    x: x,
    y: y,
    width: width,
    height: height
  }) do
    %Rectangle{
      x: x - 2,
      y: y - 2,
      width: width + 3,
      height: height + 3
    }
  end

end
