defmodule Rectangle do

  @moduledoc """
  A rectangular grid area.
  """

  @enforce_keys [:x, :y, :width, :height]

  defstruct x: nil,
    y: nil,
    width: nil,
    height: nil

  @type t :: %__MODULE__{}
  @typep coords :: {integer, integer}

  @doc """
  Create a new rectangular area.

  ### Examples
      iex> Rectangle.new(1, 2, 3, 4)
      %Rectangle{x: 1, y: 2, width: 3, height: 4}
  """
  @spec new(integer, integer, integer, integer) :: Rectangle.t
  def new(x, y, width, height) do
    %Rectangle{
      x: x,
      y: y,
      height: height,
      width: width
    }
  end

  @doc """
  Checks whether a coordinate is within the bounds of the rectangle.

  ### Examples

      iex> Rectangle.within?(%Rectangle{x: 1, y: 1, width: 1, height: 2}, {1, 3})
      true

      iex> Rectangle.within?(%Rectangle{x: 1, y: 1, width: 1, height: 1}, {1, 3})
      false
  """
  @spec within?(Rectangle.t, coords) :: boolean
  def within?(%Rectangle{x: x, y: y, width: w, height: h}, {cx, cy}) do
    (cx >= x and cx <= (x + w)) and (cy >= y and cy <= (y + h))
  end

  @doc """
  Checks whether two rectangles overlap.

  ### Examples
      iex> rect1 = Rectangle.new(2, 2, 2, 2)
      iex> rect2 = Rectangle.new(4, 4, 2, 2)
      iex> Rectangle.overlaps?(rect1, rect2)
      true

      iex> rect1 = Rectangle.new(2, 2, 2, 2)
      iex> rect2 = Rectangle.new(5, 4, 2, 2)
      iex> Rectangle.overlaps?(rect1, rect2)
      false
  """
  @spec overlaps?(Rectangle.t, Rectangle.t) :: boolean
  def overlaps?(%Rectangle{
    x: x1,
    y: y1,
    width: w1,
    height: h1
  }, %Rectangle{
    x: x2,
    y: y2,
    width: w2,
    height: h2
  } = rect) do
    cond do
      x1 > (x2 + w2) ->
        false
      x2 > (x1 + w1) ->
        false
      y1 > (y2 + h2) ->
        false
      y2 > (y1 + h1) ->
        false
      true ->
        true
    end
    # within?(rect, {x, y}) or
    #   within?(rect, {x + width, y}) or
    #   within?(rect, {x, y + height}) or
    #   within?(rect, {x + height, y + width})
  end

end
