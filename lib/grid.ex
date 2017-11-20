defmodule Grid do

  @moduledoc """
  A map grid consisting of cells.
  """

  defstruct width: 50,
    height: 50,
    cells: []

  @type t :: %__MODULE__{}
  @typep width :: integer
  @typep height :: integer
  @typep coords :: {integer, integer}

  @doc """
  Create a grid of cells given a height and width.

  ### Examples

      iex> Grid.new(3, 4)
      %Grid{width: 3, height: 4, cells: [
        [%Cell{x: 0, y: 0, val: 0}, %Cell{x: 1, y: 0, val: 0}, %Cell{x: 2, y: 0, val: 0}],
        [%Cell{x: 0, y: 1, val: 0}, %Cell{x: 1, y: 1, val: 0}, %Cell{x: 2, y: 1, val: 0}],
        [%Cell{x: 0, y: 2, val: 0}, %Cell{x: 1, y: 2, val: 0}, %Cell{x: 2, y: 2, val: 0}],
        [%Cell{x: 0, y: 3, val: 0}, %Cell{x: 1, y: 3, val: 0}, %Cell{x: 2, y: 3, val: 0}]
      ]}
  """
  @spec new(width, height) :: Grid.t
  def new(width, height) do
    cells = for y <- 0..(height - 1), do: for x <- 0..(width - 1), do: Cell.new(x, y)
    %Grid{width: width, height: height, cells: cells}
  end

  @doc """
  Gets all the cells within a given room.

  ### Examples
      iex> Grid.new(10, 10) |> Grid.cells(Room.new(Rectangle.new(2, 2, 2, 2)))
      [
        %Cell{x: 3, y: 3, val: 0},
        %Cell{x: 3, y: 2, val: 0},
        %Cell{x: 2, y: 3, val: 0},
        %Cell{x: 2, y: 2, val: 0}
      ]
  """
  @spec cells(Grid.t, Room.t) :: [Cell.t]
  def cells(%Grid{} = grid, %Room{rect: %Rectangle{
    x: x,
    y: y,
    width: width,
    height: height
  }}) do
    xr = x..(x + width - 1)
    yr = y..(y + height - 1)
    Enum.reduce(xr, [], fn x, cells ->
      Enum.reduce(yr, cells, fn y, cells ->
        # [cell_at(grid, {x, y})|cells]
        case cell_at(grid, {x, y}) do
          %Cell{} = cell ->
            [cell|cells]
          nil ->
            raise ArgumentError, "room out of bounds"
        end
      end)
    end)
  end

  @doc """
  Get a row of cells at a Y coordinate from a grid.

  ### Examples

      iex> Grid.row_at(Grid.new(3, 3), 2)
      [
        %Cell{x: 0, y: 2, val: 0},
        %Cell{x: 1, y: 2, val: 0},
        %Cell{x: 2, y: 2, val: 0}
      ]

      iex> Grid.row_at(Grid.new(3, 3), 3)
      nil

      iex> Grid.row_at(Grid.new(3, 3), 0)
      [
        %Cell{x: 0, y: 0, val: 0},
        %Cell{x: 1, y: 0, val: 0},
        %Cell{x: 2, y: 0, val: 0}
      ]

      iex> Grid.row_at(Grid.new(3, 3), -1)
      nil

      iex> Grid.row_at(Grid.new(3, 3), 10)
      nil
  """
  @spec row_at(Grid.t, integer) :: [Cell.t]
  def row_at(%Grid{
    cells: cells,
    height: height
  }, y) when y >= 0 and y < height do
    Enum.at(cells, y)
  end

  def row_at(_, _), do: nil

  @doc """
  Get a cell at coordinates from a grid.

  ### Examples

      iex> Grid.cell_at(Grid.new(5, 5), {1, 2})
      %Cell{x: 1, y: 2, val: 0}

      iex> Grid.cell_at(Grid.new(5, 5), {5, 3})
      nil

      iex> Grid.cell_at(Grid.new(5, 5), {0, 5})
      nil

      iex> Grid.cell_at(Grid.new(5, 5), {2, -6})
      nil
  """
  @spec cell_at(Grid.t, coords) :: Cell.t
  def cell_at(%Grid{
    width: width
  } = grid, {x, y}) when x >= 0 and x < width do
    grid
    |> row_at(y)
    |> case do
      nil ->
        nil
      row ->
        Enum.at(row, x)
    end
  end

  def cell_at(_, _), do: nil

  @doc """
  Updates a cell at coordinates in a grid.

  ### Examples

      iex> Grid.put_cell(Grid.new(3, 4), %Cell{x: 1, y: 2, val: 16})
      %Grid{height: 4, width: 3, cells: [
        [%Cell{x: 0, y: 0, val: 0}, %Cell{x: 1, y: 0, val: 0}, %Cell{x: 2, y: 0, val: 0}],
        [%Cell{x: 0, y: 1, val: 0}, %Cell{x: 1, y: 1, val: 0}, %Cell{x: 2, y: 1, val: 0}],
        [%Cell{x: 0, y: 2, val: 0}, %Cell{x: 1, y: 2, val: 16}, %Cell{x: 2, y: 2, val: 0}],
        [%Cell{x: 0, y: 3, val: 0}, %Cell{x: 1, y: 3, val: 0}, %Cell{x: 2, y: 3, val: 0}]
      ]}
  """
  @spec put_cell(Grid, Cell.t) :: Grid.t
  def put_cell(%Grid{cells: cells} = grid, %Cell{x: x, y: y} = cell) do
    row =
      cells
      |> Enum.at(y)
      |> List.replace_at(x, cell)
    new_cells = List.replace_at(cells, y, row)
    %{grid | cells: new_cells}
  end

end
