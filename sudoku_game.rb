require 'rubygems'
require 'colorize'

class SudokuGame
  attr_accessor :tiles
  def initialize(input = nil)
    @tiles = []
    if input
      input = input.split(" ").map{|x| x.split("")}
      if input.map(&:count) != [9]*9
        raise "input is wrong"
      end
      build_tiles(input)
      puts "\nGiven Sudoku Puzzle:\n\n"
      pretty_print
    end
  end

  def solve
    run_elimination_algorithm
    if solved?
      puts "Solved!!!"
      pretty_print
      return
    else
      p "make best guess"
      make_best_guess
    end
  end

  def run_elimination_algorithm
    loop do
      puts solved_tile_count_before = solved_tile_count
      @tiles.flatten.each do |tile|
        unless tile.value
          tile.update_candidates
          tile.set_value
        end
      end
      pretty_print
      puts solved_tile_count_after = solved_tile_count

      break if solved? || solved_tile_count_before == solved_tile_count_after
    end
  end

  def make_best_guess
    x = tile_to_try.x
    y = tile_to_try.y
    candidates = tile_to_try.candidates

    games_to_try.each_with_index do |game, i|
      puts "Solving sub-puzzle: Row #{x} Column #{y} Guess: #{candidates[i]}"
      game.pretty_print
      return game.solve
    end
  end

  def unsolved?
    @tiles.flatten.any? { |tile| tile.value.nil? }
  end

  def solved?
    @tiles.flatten.all? { |tile| !tile.value.nil? }
  end

  def unsolved_tiles
    @tiles.flatten.select{|x| x.value.nil? }
  end

  def tile_to_try
    unsolved_tiles.sort{|x, y| x.candidates.length <=> y.candidates.length }.first
  end

  def games_to_try
    @games_to_try ||= tile_to_try.candidates.map do |num|
      game = Marshal.load(Marshal.dump(self))
      game.tiles[tile_to_try.x-1][tile_to_try.y-1].set_value(num)
      game
    end
  end

  def solved_tile_count
    @tiles.flatten.map(&:value).compact.count
  end

  def add(x, y, value)
    tile = @tiles[x-1][y-1]
    tile.value = value
  end

  def build_tiles(input=nil)
    @tiles = (0..8).map do |x|
      (0..8).map do |y|
        value = input[x][y]
        if value == "."
          Tile.new(self, x+1, y+1, nil, false)
        else
          Tile.new(self, x+1, y+1, value.to_i, true)
        end
      end
    end
  end

  def pretty_print
    @tiles.each_with_index do |row, i|
      row.each_with_index do |tile, j|
        color = tile.given ? :red : :green
        print tile.value ? tile.value.to_s.send(color) : "*"
        putc " "; putc "|" if j %3 == 2
      end
      puts; puts "-"*22 if i % 3 == 2
    end

    puts "Tiles remaining to be solved: #{81 - solved_tile_count}\n\n"
  end
end

class Tile
  attr_accessor :value, :given, :x, :y

  def initialize(game, x, y, value, given)
    @game = game
    @x = x
    @y = y
    @value  = value
    @candidates = nil
    @given = given
  end

  def set_value(value=nil)
    if value
      @value = value
      @candidates = []
    else
      if candidates.count == 1
        @value = candidates.first
        @candidates = []
      elsif derived_number
        @value = derived_number
        @candidates = []
      end
    end
  end

  def derived_number
    [x_neighbors, y_neighbors, z_neighbors].each do |neighbors|
      neighbor_candidates = (neighbors - [self]).map(&:candidates).flatten
      exclusive_candidates = candidates - neighbor_candidates
      return exclusive_candidates[0] if exclusive_candidates.count == 1
    end
    nil
  end

  def candidates
    @value ? [] : (@candidates || update_candidates)
  end

  def update_candidates
    impossible_values = x_neighbors.map(&:value) | y_neighbors.map(&:value) | z_neighbors.map(&:value)
    @candidates = (1..9).to_a - impossible_values
  end

  def x_neighbors
    @game.tiles[x-1]
  end

  def y_neighbors
    @game.tiles.map{ |tiles| tiles[y-1] }
  end

  def z_neighbors
    x1 = ((x - 1) / 3 ) * 3
    y1 = ((y - 1) / 3 ) * 3
    (x1..x1+2).map { |x| (y1..y1+2).map { |y| @game.tiles[x][y] } }.flatten
  end
end

# game = SudokuGame.new("586374912 137952864 249816573 872543196 693781245 415629738 954237681 721468359 368195427")
# game = SudokuGame.new("..6.7.9.. 1..9....4 ...8..5.3 .7.5...9. ..37.1... 4...2.7.8 .5.2..6.. 7....8... 3..1..4..")
game = SudokuGame.new("61.....8. .2.53..9. ..3...6.. ..94..... 4..1.7..9 .....98.. ..4...1.. .5..21.3. .3.....76")
game.solve
