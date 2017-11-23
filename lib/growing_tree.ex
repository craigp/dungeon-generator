defmodule GrowingTree do

  @moduledoc false

  require Bitwise

  @room_cell 16

  def run(width \\ 50, height \\ 50) do
    # create a grid of cells with the give height and width
    grid = Grid.new(width, height)
    # grid = 0..(height - 1) |> Enum.map(fn _y ->
    #   0..(width - 1) |> Enum.map(fn _x ->
    #     0
    #   end)
    # end)
    IO.write "\e[2J" # clear the screen
    {grid, rooms} = create_rooms(grid, 1000)
    grid = find_connectors(grid, rooms)
    grid = carve_passages(grid, rooms)
    grid = remove_deadends(grid)
    print(grid)
    IO.inspect Grid.cell_at(grid, {0, 0})
    :ok
  end

  def opposite({card, _}), do: opposite(card)

  def opposite(card) do
    {_, {bw, _, _}} = case card do
      :north -> :south
      :south -> :north
      :west -> :east
      :east -> :west
    end |> get_direction
  end

  def get_opposite_direction(dir) do
    case dir do
      :north -> :south
      :south -> :north
      :west -> :east
      :east -> :west
    end
  end

  def get_directions do
    [
      north: {1, 0, -1},
      south: {2, 0, 1},
      east: {4, 1, 0},
      west: {8, -1, 0}
    ]
  end

  def get_random_direction do
    get_directions()
    |> Enum.shuffle
    |> List.first
  end

  def get_direction(card) do
    {:ok, direction} = Keyword.fetch(get_directions(), card)
    {card, direction}
  end

  def get_exits(%Cell{val: val} = cell) do
    Enum.reduce(get_directions(), [], fn {card, {_bw, _dx, _dy}} = direction, exits ->
      if Cell.open?(cell, card) do
        [direction|exits]
      else
        exits
      end
    end)
  end

  def remove_deadends(%Grid{cells: cells} = grid) do
    Enum.reduce(cells, [], fn row, deadends ->
      Enum.reduce(row, deadends, fn cell, deadends ->
        unless Cell.is_doorway?(cell) do
          case get_exits(cell) do
            [exit|[]] -> # only if the cell has _only_ one exit
              [{cell, exit}|deadends]
            _ ->
              deadends
          end
        else
          deadends
        end
      end)
    end)
    |> remove_deadends(grid)
  end

  def remove_deadends([], grid), do: grid

  def remove_deadends([{%Cell{x: x, y: y} = cell, {card, {bw, dx, dy}} = exit} = deadend|deadends], grid) do
    # IO.puts "removing deadend at #{x}/#{y} with exit #{card}"
    grid = update_cell_with(grid, x, y, 0) # not sure why I do this, this clears all exits
    nx = x + dx
    ny = y + dy
    # get the cell in the direction of the exit
    %Cell{val: nval} = ncell = Grid.cell_at(grid, {nx, ny})
    #get the opposite direction, we're going to close the exit behind us
    {ncard, {bw, _, _}} = opposite(card)
    # exits = get_cell_at(grid, nx, ny) |> get_exits
    # IO.puts "updating exit cell at #{nx}/#{ny} xor with #{bw} with #{length(exits)} exits"
    # grid = update_cell_with(grid, nx, ny, Bitwise.bxor(nval, bw))
    ncell = Cell.close(ncell, ncard)
    grid = Grid.put_cell(grid, ncell)
    exits = get_exits(ncell)
    # IO.puts "cell should now have one less exit: #{length(exits)}"
    if length(exits) == 1 do
      deadends = [{ncell, List.first(exits)}|deadends]
    end
    print grid
    :timer.sleep(1)
    remove_deadends(deadends, grid)
  end

  def find_connectors(%Grid{} = grid, rooms) do
    Enum.map(rooms, fn %Room{rect: %Rectangle{x: rx, y: ry, width: width, height: height}} = room ->
      y = Enum.random(ry..(ry + height - 1))
      x = Enum.random([rx, (rx + width - 1)])
      {{rx, ry, width, height}, x, y}
    end)
    |> Enum.reduce(grid, fn {{rx, _ry, _, _}, x, y}, grid ->
      {card, {_bw, dx, dy}} = direction = if x == rx do
        # on the eastern side of the room
        get_direction(:west) # open to the west
      else
        # on the western side of the woom
        get_direction(:east) # open to the east
      end
      # open the cell in the direction of the doorway
      cell =
        grid
        |> Grid.cell_at({x, y})
        |> Cell.is_doorway
        |> Cell.open(card)
      grid = Grid.put_cell(grid, cell)
      # get the next cell in that direction (outside the room)
      nx = x + dx
      ny = y + dy
      {ncard, {_bw, _, _}} = opposite(direction)
      # open this cell in the opposite direction, into the room
      next_cell =
        grid
        |> Grid.cell_at({nx, ny})
        |> Cell.open(ncard)
      Grid.put_cell(grid, next_cell)
    end)
  end

  @doc """
  For a given number of attempts and a grid of cells that has a height and
  width, create a list of rooms that do not overlap each other.
  """
  def create_rooms(%Grid{
    height: height,
    width: width,
    cells: cells
  } = grid, attempts \\ 200) do
    rooms = Enum.reduce(1..attempts, [], fn _n, rooms ->
      room = create_room(grid)
      if Enum.any?(rooms, &Room.overlaps?(&1, room)) do
        rooms
      else
        [room|rooms]
      end
    end)
    grid = Enum.reduce(rooms, grid, fn room, grid ->
      cells =
        grid
        |> Grid.cells(room)
        |> Enum.map(&Cell.in_room/1)
      Grid.put_cells(grid, cells)
    end)
    {grid, rooms}
  end

    # def create_room(width, height, grid) do
    # room_size_range = 2..3
    # size = (room_size_range |> Enum.random)
    # room_width = size
    # room_height = size
    # case Enum.random(1..2) do
    #   1 ->
    #     room_width = (size + Enum.random(0..1)) * 2
    #   2 ->
    #     room_height = (size + Enum.random(0..1)) * 2
    # end
    # # get a random y position, making sure to avoid the top and bottom wall
    # room_y_index = Enum.random(1..(height - room_height - 2))
    # # get a random x position, making sure to avoid the left and right wall
    # room_x_index = Enum.random(1..(width - room_width - 2))
    # IO.inspect {room_x_index, room_y_index, room_width, room_height}
    # {room_x_index, room_y_index, room_width, room_height}
  # end

  @doc """
  Create a room, being an `x` & `y` start coordinate and a width and height.
  """
  def create_room(%Grid{height: height, width: width}) do
    room_width = random_dimension()
    room_height = random_dimension()
    # get a random y position, making sure to avoid the top and bottom wall
    room_y_index = Enum.random(1..(height - room_height - 2))
    # get a random x position, making sure to avoid the left and right wall
    room_x_index = Enum.random(1..(width - room_width - 2))
    %Room{
      rect: %Rectangle{
        x: room_x_index,
        y: room_y_index,
        width: room_width,
        height: room_height
      }
    }
  end

  def carve_passages(%Grid{height: height, width: width} = grid, rooms) do
    [room|_] = Enum.shuffle(rooms)
    cells = Grid.cells(grid, room)
    %Cell{x: x, y: y} = doorway = Enum.find(cells, &Cell.is_doorway?/1)
    [{card, {_, dx, dy}}|_] = get_exits(doorway)
    cells = [{x + dx, y + dy}]
    # x = Enum.random(0..width-1)
    # y = Enum.random(0..height-1)
    carve_cells(grid, cells)
  end

  def update_cell(%Grid{} = grid, x, y, 0) do
    update_cell_with(grid, x, y, 0)
  end

  def update_cell(%Grid{} = grid, x, y, bw) do
    %Cell{val: val} = cell = Grid.cell_at(grid, {x, y})
    val = Bitwise.bor(val, bw)
    cell = %{cell | val: val}
    Grid.put_cell(grid, cell)
  end

  def update_cell_with(%Grid{} = grid, x, y, val) do
    %Cell{} = cell = Grid.cell_at(grid, {x, y})
    cell = %{cell | val: val}
    Grid.put_cell(grid, cell)
  end

  # def get_cell_at(grid, x, y) do
  #   row = Enum.at(grid, y)
  #   Enum.at(row, x)
  # end

  def carve_cells(grid, cells) when length(cells) > 0 do
    directions =
      get_directions
      |> Enum.shuffle
    carve_cells(grid, cells, directions)
  end

  def carve_cells(grid, _cells) do
    grid
  end

  def carve_cells(grid, cells, directions) when is_list(directions) do
    cell = List.first(cells)
    carve_cells(grid, cells, cell, directions)
  end

  def carve_cells(grid, cells, {card, _}) do
    {direction, directions} = Keyword.pop(get_directions, card)
    cell = List.first(cells)
    carve_cells(grid, cells, cell, directions, {card, direction})
  end

  def carve_cells(grid, cells, cell, directions) when length(directions) > 0 do
    key = directions |> Keyword.keys |> List.first
    {direction, directions} = Keyword.pop(directions, key)
    carve_cells(grid, cells, cell, directions, {key, direction})
  end

  def carve_cells(grid, cells, _cell, _directions) do
    [_removed|updated_cells] = cells
    carve_cells(grid, updated_cells)
  end

  def carve_cells(grid, cells, {x, y} = cell, directions, {card, {bw, dx, dy}} = direction) when length(cells) > 0 do
    nx = x + dx
    ny = y + dy
    case Grid.cell_at(grid, {nx, ny}) do
      %Cell{val: 0} = next_cell ->
        grid_cell = Cell.open(Grid.cell_at(grid, cell), card)
        next_cell = Cell.open(next_cell, get_opposite_direction(card))
        grid =
          grid
          |> Grid.put_cell(grid_cell)
          |> Grid.put_cell(next_cell)
        print(grid)
        :timer.sleep(1)
        # we want to "weight" it in favour of going in straighter lines, so reuse the same direction
        carve_cells(grid, [{nx, ny}|cells], direction)
        # carve_cells(grid, cells)
      _ ->
        carve_cells(grid, cells, cell, directions)
    end
  end

  def write(text, color \\ 0) do
    [String.to_atom("color#{color}_background"), text] |> Bunt.ANSI.format |> IO.write
  end

  def print(%Grid{cells: cells}, current_cell \\ {0, 0}) do
    IO.write "\e[H" # move to upper-left
    IO.write " "
    # write the top border
    1..(length(Enum.at(cells, 0)) * 2 - 1) |> Enum.each(fn _n ->
      IO.write "_"
    end)
    IO.puts " "
    cells
    |> Enum.with_index
    |> Enum.each(fn {row, y} ->
      IO.write "|"
      row
      |> Enum.with_index
      |> Enum.each(fn {%Cell{val: val} = cell, x} ->
        if {x, y} == current_cell do
          [:color236_background, :color150, "X|"]
          |> Bunt.ANSI.format
          |> IO.write
        else
          if Cell.in_room?(cell) do
            # this is a room
            # get the cell to the right/west
            %Cell{val: next_val} = next_cell = Enum.at(row, x + 1)
            if Cell.in_room?(next_cell) do # cell to the right/east is a room cell
              if Cell.is_doorway?(cell) do
                [:color236_background, :color150, "d"]
                |> Bunt.ANSI.format
                |> IO.write
                [:color236_background, :color240, "."]
                |> Bunt.ANSI.format
                |> IO.write
              else # cell to the right/east is *not* a room cell
                [:color236_background, :color240, ".."]
                |> Bunt.ANSI.format
                |> IO.write
              end
            else
              if Cell.is_doorway?(cell) do
                [:color236_background, :color150, "d "]
                |> Bunt.ANSI.format
                |> IO.write
              else
                [:color236_background, :color240, "."]
                |> Bunt.ANSI.format
                |> IO.write
                [:color236_background, "|"]
                |> Bunt.ANSI.format
                |> IO.write
              end
            end
          else
            # not a room
            if val != 0 do
              # not empty (probably a corridor)
              if Cell.open?(cell, :south) do
                " " # open to the south
              else
                "_" # not open to the south
              end |> write(236)
              if Cell.open?(cell, :east) do
                # get the cell to the east/right
                case Enum.at(row, x + 1) do
                  %Cell{val: next_val} = next_cell ->
                    if Cell.open?(next_cell, :south) do # is the next cell open to the south?
                      " "
                    else
                      "_"
                    end
                  nil ->
                    "_"
                end
              else
                "|" # not open to the east
              end |> write(236)
            else
              "_|" |> write(240)
            end
          end
        end
      end)
      IO.puts ""
    end)
  end

  def random_dimension do
    (Enum.random(2..3) + Enum.random(0..1)) * 2
  end

end
