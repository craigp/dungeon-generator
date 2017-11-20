defmodule GrowingTree do
  require Bitwise

  def run(width \\ 50, height \\ 50) do
    grid = 0..(height - 1) |> Enum.map(fn _y ->
      0..(width - 1) |> Enum.map(fn _x ->
        0
      end)
    end)
    IO.write "\e[2J" # clear the screen
    {grid, rooms} = create_rooms(width, height, grid, 1000)
    grid = carve_passages(width, height, grid)
    grid = find_connectors(grid, rooms)
    print grid
    grid = remove_deadends(grid)
    print(grid)
  end

  def opposite({card, _}), do: opposite(card)

  def opposite(card) do
    {_, {bw, _, _}} = case card do
      :n -> :s
      :s -> :n
      :w -> :e
      :e -> :w
    end |> get_direction
    bw
  end

  def get_directions do
    %{
      n: {1, 0, -1},
      s: {2, 0, 1},
      e: {4, 1, 0},
      w: {8, -1, 0}
    }
  end

  def get_direction(card) do
    {:ok, direction} = Map.fetch(get_directions, card)
    {card, direction}
  end

  def get_exits(cell) do
    Enum.reduce(get_directions, [], fn {_card, {bw, _dx, _dy}} = direction, exits ->
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

  def remove_deadends({x, y, {card, {bw, dx, dy}} = exit} = deadend, deadends, grid) do
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
    # print grid
    # :timer.sleep(10)
    remove_deadends(deadends, grid)
  end

  def find_connectors(grid, rooms) do
    Enum.map(rooms, fn {x, y, width, height} = room ->
      y = Enum.random(y..(y + height))
      x = Enum.random([x, x + width])
      {room, x, y}
    end)
    |> Enum.reduce(grid, fn {{rx, ry, _, _}, x, y}, grid ->
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
      grid = update_cell(grid, nx, ny, opposite(direction))
    end)
  end

  def overlaps?(rooms, {x, y, width, height}) do
    Enum.any?(rooms, fn {other_x, other_y, other_width, other_height} ->
      not(((x + width + 2) < other_x) or
        ((other_x + other_width + 2) < x) or
        ((y + height + 2) < other_y) or
        ((other_y + other_height + 2) < y))
    end)
  end

  def create_rooms(width, height, grid, attempts \\ 200) do
    rooms = Enum.reduce(1..attempts, [], fn _n, rooms ->
      room = create_room(width, height, grid)
      unless overlaps?(rooms, room) do
        [room|rooms]
      else
        rooms
      end
    end)
    grid = rooms |> Enum.reduce(grid, fn {x, y, width, height}, grid ->
      y..(y + height) |> Enum.reduce(grid, fn uy, grid ->
        x..(x+width) |> Enum.reduce(grid, fn ux, grid ->
          update_cell(grid, ux, uy, 16)
        end)
      end)
    end)
    {grid, rooms}
  end

  def create_room(width, height, grid) do
    room_size_range = 2..3
    size = (room_size_range |> Enum.random)
    room_width = size
    room_height = size
    case Enum.random(1..2) do
      1 ->
        room_width = (size + Enum.random(0..1)) * 2
      2 ->
        room_height = (size + Enum.random(0..1)) * 2
    end
    # get a random y position, making sure to avoid the top and bottom wall
    room_y_index = Enum.random(1..(height - room_height - 2))
    # get a random x position, making sure to avoid the left and right wall
    room_x_index = Enum.random(1..(width - room_width - 2))
    {room_x_index, room_y_index, room_width, room_height}
  end

  def carve_passages(width, height, grid) do
    x = Enum.random(0..(width - 1))
    y = Enum.random(0..(height - 1))
    cells = [{x, y}]
    carve_cells(grid, cells)
  end

  def update_cell(grid, x, y, 0) do
    row = Enum.at(grid, y)
    row = List.replace_at(row, x, 0)
    List.replace_at(grid, y, row)
  end

  def update_cell(grid, x, y, bw) do
    row = Enum.at(grid, y)
    cell = Enum.at(row, x)
    cell = Bitwise.bor(cell, bw)
    row = List.replace_at(row, x, cell)
    List.replace_at(grid, y, row)
  end

  def update_cell_with(grid, x, y, val) do
    row = Enum.at(grid, y)
    row = List.replace_at(row, x, val)
    List.replace_at(grid, y, row)
  end

  def get_cell_at(grid, x, y) do
    row = Enum.at(grid, y)
    Enum.at(row, x)
  end

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
    {direction, directions} = Map.pop(get_directions, card)
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
    row = Enum.at(grid, ny)
    if row do
      grid_cell = Enum.at(row, nx)
      if ny in 0..(length(grid) - 1) and nx in 0..(length(row) - 1) and grid_cell == 0 do
        grid =
          grid
          |> update_cell(x, y, bw)
          |> update_cell(nx, ny, opposite(direction))
        print(grid)
        :timer.sleep(10)
        cells = [{nx, ny}|cells]
        # we want to "weight" it in favour of going in straighter lines, so reuse the same direction
        carve_cells(grid, cells, direction)
        # carve_cells(grid, cells)
      else
        carve_cells(grid, cells, cell, directions)
      end
    else
      carve_cells(grid, cells, cell, directions)
    end
  end

  def write(text, color \\ 0) do
    [String.to_atom("color#{color}_background"), text] |> Bunt.ANSI.format |> IO.write
  end

  def print(grid) do
    IO.write "\e[H" # move to upper-left
    IO.write " "
    1..(length(Enum.at(grid, 0)) * 2 - 1) |> Enum.each(fn _n ->
      IO.write "_"
    end)
    IO.puts " "
    Enum.each(grid, fn row ->
      IO.write "|"
      row
      |> Enum.with_index
      |> Enum.each(fn {cell, x} ->
        if Bitwise.band(cell, 16) != 0 do
          # this is a room
          next_cell = Enum.at(row, x + 1)
          if Bitwise.band(next_cell, 16) != 0 do # cell to the right/west is a room cell
            if Bitwise.band(cell, 32) != 0 do # door
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
            if Bitwise.band(cell, 32) != 0 do
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
          if cell != 0 do
            # not empty (probably a corridor)
            if Bitwise.band(cell, 2) != 0 do
              " " # open to the south
            else
              "_" # not open to the south
            end |> write(236)
            if Bitwise.band(cell, 4) != 0 do
              # open to the east
              next_cell = Enum.at(row, x + 1)
              if Bitwise.bor(next_cell, 2) != 0 do # is the next cell open to the south?
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
      end)
      IO.puts ""
    end)
  end

end
