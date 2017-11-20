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
    # {grid, rooms} = create_rooms(grid, 1000)
    grid = carve_passages(grid)
    # grid = find_connectors(grid, rooms)
    print grid
    # grid = remove_deadends(grid)
    # print(grid)
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
    bw
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

  def get_exits(cell) do
    Enum.reduce(get_directions(), [], fn {_card, {bw, _dx, _dy}} = direction, exits ->
      if Bitwise.band(cell, bw) != 0 do
        [direction|exits]
      else
        exits
      end
    end)
  end

  def remove_deadends(grid) do
    grid
    |> Enum.with_index
    |> Enum.reduce([], fn {row, y}, deadends ->
      row
      |> Enum.with_index
      |> Enum.reduce(deadends, fn {cell, x}, deadends ->
        if Bitwise.band(cell, 32) == 0 do # not a door
          exits = get_exits(cell)
          if length(exits) == 1 do
            [{x, y, List.first(exits)}|deadends]
          else
            deadends
          end
        else
          deadends
        end
      end)
    end)
    |> remove_deadends(grid)
  end

  def remove_deadends([], grid) do
    grid
  end

  def remove_deadends([deadend|deadends], grid) do
    # Enum.random(deadends) |> remove_deadends(deadends, grid)
    remove_deadends(deadend, deadends, grid)
  end

  def remove_deadends({x, y, {card, {_bw, dx, dy}} = _exit} = _deadend, deadends, grid) do
    # IO.puts "removing deadend at #{x}/#{y} with exit #{card}"
    grid = update_cell_with(grid, x, y, 0)
    nx = x + dx
    ny = y + dy
    ncell = get_cell_at(grid, nx, ny)
    bw = opposite(card)
    # exits = get_cell_at(grid, nx, ny) |> get_exits
    # IO.puts "updating exit cell at #{nx}/#{ny} xor with #{bw} with #{length(exits)} exits"
    grid = update_cell_with(grid, nx, ny, Bitwise.bxor(ncell, bw))
    exits = get_cell_at(grid, nx, ny) |> get_exits
    # IO.puts "cell should now have one less exit: #{length(exits)}"
    if length(exits) == 1 do
      # IO.puts "added to deadends"
      deadends = [{nx, ny, List.first(exits)}|deadends]
    end
    # print(grid)
    # :timer.sleep(1)
    remove_deadends(deadends, grid)
  end

  def find_connectors(grid, rooms) do
    Enum.map(rooms, fn {x, y, width, height} = room ->
      y = Enum.random(y..(y + height))
      x = Enum.random([x, x + width])
      {room, x, y}
    end)
    |> Enum.reduce(grid, fn {{rx, _ry, _, _}, x, y}, grid ->
      grid = update_cell(grid, x, y, 32)
      {_card, {bw, dx, dy}} = direction = if x == rx do
        # on the eastern side of the room
        get_direction(:w) # open to the west
      else
        # on the western side of the woom
        get_direction(:e) # open to the east
      end
      grid = update_cell(grid, x, y, bw)
      nx = x + dx
      ny = y + dy
      _grid = update_cell(grid, nx, ny, opposite(direction))
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
      grid
      |> Grid.cells(room)
      |> Enum.map(&Cell.in_room/1)
      |> Enum.reduce(grid, fn cell, grid ->
        Grid.put_cell(grid, cell)
      end)
    end)
    {grid, rooms}
  end

  @doc """
  Create a room, being an `x` & `y` start coordinate and a width and height.
  """
  def create_room(%Grid{height: height, width: width}) do
    # pick a random room size between 2 & 3
    size = Enum.random(2..3)
    # randomize the dimensions a bit
    room_width = size
    room_height = size
    case Enum.random(1..2) do
      1 ->
        room_width = (size + Enum.random(0..1)) * 2
      2 ->
        room_height = (size + Enum.random(0..1)) * 2
    end
    # get a random y position, making sure to avoid the top and bottom wall
    room_y_index = Enum.random(2..(height - room_height - 2))
    # get a random x position, making sure to avoid the left and right wall
    room_x_index = Enum.random(2..(width - room_width - 2))
    %Room{
      rect: %Rectangle{
        x: room_x_index,
        y: room_y_index,
        width: room_width,
        height: room_height
      }
    }
  end

  def carve_passages(%Grid{height: height, width: width} = grid) do
    x = Enum.random(1..width)
    y = Enum.random(1..height)
    cells = [{x, y}]
    carve_cells(grid, cells)
  end

  def update_cell(cells, x, y, 0) do
    row = Enum.at(cells, y)
    %Cell{} = cell = Enum.at(row, x)
    cell = %{cell | val: 0}
    row = List.replace_at(row, x, cell)
    List.replace_at(cells, y, row)
  end

  def update_cell(cells, x, y, bw) do
    row = Enum.at(cells, y)
    %Cell{val: val} = cell = Enum.at(row, x)
    val = Bitwise.bor(val, bw)
    cell = %{cell | val: val}
    row = List.replace_at(row, x, cell)
    List.replace_at(cells, y, row)
  end

  def update_cell_with(cells, x, y, val) do
    row = Enum.at(cells, y)
    %Cell{} = cell = Enum.at(row, x)
    cell = %{cell | val: val}
    row = List.replace_at(row, x, cell)
    List.replace_at(cells, y, row)
  end

  def get_cell_at(grid, x, y) do
    row = Enum.at(grid, y)
    Enum.at(row, x)
  end

  def carve_cells(grid, []), do: grid

  def carve_cells(grid, [cell|_] = cells) do
    carve_cells(grid, cells, cell, get_random_direction())
  end

  def carve_cells(grid, cells, {x, y} = cell, {card, {bw, dx, dy}} = direction) do
    IO.puts "carving #{card} from #{x}/#{y} (#{length(cells)} cells left)"
    nx = x + dx
    ny = y + dy
    case Grid.cell_at(grid, {nx, ny}) do
      %Cell{val: 0} = grid_cell ->
        grid_cell =
          grid_cell
          |> Cell.open(card)
          |> Cell.open(get_opposite_direction(card))
        grid = Grid.put_cell(grid, grid_cell)
        print(grid, cell)
        :timer.sleep(100)
        # we want to "weight" it in favour of going in straighter lines, so reuse the same direction
        carve_cells(grid, cells, {nx, ny}, direction)
        # carve_cells(grid, cells)
      _ ->
        carve_cells(grid, cells)
    end
  end

  # def carve_cells(grid, cells, {x, y} = cell, directions, {card, {bw, dx, dy}} = direction) when length(cells) > 0 do
  #   nx = x + dx
  #   ny = y + dy
  #   row = Enum.at(grid, ny)
  #   if row do
  #     grid_cell = Enum.at(row, nx)
  #     if ny in 0..(length(grid) - 1) and nx in 0..(length(row) - 1) and grid_cell == 0 do
  #       grid =
  #         grid
  #         |> update_cell(x, y, bw)
  #         |> update_cell(nx, ny, opposite(direction))
  #       # print(grid)
  #       # :timer.sleep(10)
  #       cells = [{nx, ny}|cells]
  #       # we want to "weight" it in favour of going in straighter lines, so reuse the same direction
  #       carve_cells(grid, cells, direction)
  #       # carve_cells(grid, cells)
  #     else
  #       carve_cells(grid, cells, cell, directions)
  #     end
  #   else
  #     carve_cells(grid, cells, cell, directions)
  #   end
  # end

  # def carve_cells(%Grid{cells: grid_cells} = grid, [{x, y}|_] = cells, [{card, {_bw, dx, dy}} = direction|directions]) do
  #   IO.puts "#{length(grid_cells)} grid cells"
  #   IO.puts "carving #{card} from #{x}/#{y} (#{length(directions)} directions left, #{length(cells)} cells left)"
  #   nx = x + dx
  #   ny = y + dy
  #   case Grid.cell_at(grid, {nx, ny}) do
  #     %Cell{} = grid_cell ->
  #       grid_cell =
  #         grid_cell
  #         |> Cell.open(card)
  #         |> Cell.open(get_opposite_direction(card))
  #       grid = Grid.put_cell(grid, grid_cell)
  #       print(grid)
  #       :timer.sleep(1)
  #       # we want to "weight" it in favour of going in straighter lines, so reuse the same direction
  #       carve_cells(grid, [{nx, ny}|cells], [direction|Enum.shuffle(directions)])
  #       # carve_cells(grid, cells)
  #     nil ->
  #       IO.puts "no cell found"
  #       carve_cells(grid, cells, directions)
  #   end
  # end

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
        if Bitwise.band(val, 16) != 0 do
          # this is a room
          %Cell{val: next_val} = Enum.at(row, x + 1)
          if Bitwise.band(next_val, 16) != 0 do # cell to the right/west is a room cell
            if Bitwise.band(val, 32) != 0 do # door
              [:color236_background, :color150, "d"]
              |> Bunt.ANSI.format
              |> IO.write
              [:color236_background, :color240, "."]
              |> Bunt.ANSI.format
              |> IO.write
            else # cell to the right/west is *not* a room cell
              [:color236_background, :color240, ".."]
              |> Bunt.ANSI.format
              |> IO.write
            end
          else
            if Bitwise.band(val, 32) != 0 do
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
            if Bitwise.band(val, 2) != 0 do
              " " # open to the south
            else
              "_" # not open to the south
            end |> write(236)
            if Bitwise.band(val, 4) != 0 do
              # open to the east
              %Cell{val: next_val} = Enum.at(row, x + 1)
              if Bitwise.bor(next_val, 2) != 0 do # is the next cell open to the south?
                " "
              else
                "_"
              end
            else
              "|" # not open to the east
            end |> write(236)
          else
            "_|" |> write(240)
          end
        end
        if {x, y} == current_cell do
          [:color236_background, :color150, "X"]
          |> Bunt.ANSI.format
          |> IO.write
        end
      end)
      IO.puts ""
    end)
  end

end
