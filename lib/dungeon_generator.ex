defmodule DungeonGenerator do
  use Application

  # def start(_type, _args) do
  #   IO.puts "Starting"
  # end

  # def stop(_args) do
  #   IO.puts "Stopping"
  # end

  def main(_args) do
    grow
  end

  # def run do
  #   Dungeon.run
  # end

  def grow do
    GrowingTree.run
  end

end
