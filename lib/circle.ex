defmodule Circle do

  @moduledoc """
  A circular area on the grid.
  """

  @enforce_keys [:x, :y, :radius]

  defstruct x: nil,
    y: nil,
    radius: nil

  @type t :: %__MODULE__{}
  @typep coords :: {integer, integer}

  @doc """
  Checks whether a coordinate is in the bounds of the circle.

  ### Examples

      iex> Circle.within?(%Circle{x: 3, y: 3, radius: 3}, {2, 2})
      true

      iex> Circle.within?(%Circle{x: 3, y: 3, radius: 2}, {2, 2})
      false

      iex> Circle.within?(%Circle{x: 3, y: 3, radius: 1}, {2, 2})
      false
  """
  @spec within?(Circle.t, coords) :: boolean
  def within?(%Circle{x: x, y: y, radius: r}, {cx, cy}) do
    d = r * 2
    (cx * cx) + (cy * cy) < ((d * d) / 4)
  end

end
