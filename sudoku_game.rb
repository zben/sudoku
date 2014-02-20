class SudokuGame
  attr_accessor :tiles

  @@time = 0

  def initialize(input=nil)
    @tiles = []

    if input
      input = input.split(" ").map{|x| x.split("")}

      build_tiles(input)
      pretty_print
    end
  end

  def solve
    total_value_before = total_value
    total_value_after = nil
    while not_solved? #&& total_value_before != total_value_after
      total_value_before = total_value

      @tiles.flatten.each do |tile|
        # p tile
        unless tile.value
          tile.update_candidates
          tile.set_value
        end
        # p tile
      end

      total_value_after = total_value
    end

    pretty_print
    # if !not_solved?
    #   p "solved!!!"
    #   pretty_print
    #   return
    # elsif total_value_after == total_value_before
    #   p "tried setting value, now trying different games"
    #   p tile_to_try
    #   p games_to_try: games_to_try.count

    #   games_to_try.each(&:pretty_print)

    #   games_to_try.each do |game|
    #     puts "TRY A subgame #{@@time += 1}"
    #     game.pretty_print
    #     # sleep 1
    #     game.solve
    #   end
    # end
  end

  def not_solved?
    @tiles.flatten.any? { |tile| tile.value.nil? }
  end

  def tile_to_try
    @tiles_to_try ||= @tiles.flatten.select{|x| x.value.nil? }.sort{|x, y| x.candidates.length <=> y.candidates.length }.first
  end

  def games_to_try
    tile = tile_to_try

    @games_to_try ||= tile.candidates.map do |num|
      game = Marshal.load(Marshal.dump(self))

      game.tiles[tile.x-1][tile.y-1].set_value(num)
      game
    end
  end

  def output
    @tiles.map do |row|
      row.map(&:serialize).join
    end.join(" ")
  end

  def total_value
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
          Tile.new(self, x, y, nil, false)
        else
          Tile.new(self, x, y, value.to_i, true)
        end
      end
    end
  end

  def pretty_print
    require 'rubygems'
    require 'colorize'

    @tiles.each_with_index do |row, i|
      row.each_with_index do |tile, j|
        if tile.given
          print(tile.value ? tile.value.to_s.red : "*")
        else
          print(tile.value ? tile.value.to_s.green : "*")
        end
        putc " "
        putc "|" if j %3 == 2
      end
      puts
      puts "-"*22 if i % 3 == 2
    end
    puts total_value
    puts
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

  def to_s
    {x: y, y: y, value: value, given: given, candidates: @candidates}
  end

  def serialize
    value ? value.to_s : "."
  end

  def set_value(value=nil)
    if value
      @value = value
      @candidates = []
    else
      if candidates.count == 1
        @value = candidates.first
        @candidates = []
      # elsif derived_number
      #   @value = derived_number
      #   @candidates = []
      end
    end
  end

  def derived_number
    x_difference = candidates - x_candidates
    y_difference = candidates - y_candidates
    z_difference = candidates - z_candidates

    [x_difference, y_difference, z_difference].each do |diff|
      if diff.count == 1
        return diff[0]
      else
        return nil
      end
    end
  end

  def candidates
    return [] if @value

    @candidates ||= range - (x_occupied | y_occupied | z_occupied)
  end

  def update_candidates
    @candidates = nil
    candidates
  end

  def x_occupied
    @game.tiles[x-1].map(&:value)
  end

  def y_occupied
    @game.tiles.map{ |tiles| tiles[y] }.map(&:value)
  end

  def z_occupied
    x1 = x - x % 3
    y1 = y - y % 3
    (x1..x1+2).map do |x|
      (y1..y1+2).map do |y|
        @game.tiles[x][y].value
      end
    end.flatten
  end

  def x_candidates
    (@game.tiles[x] - [self]).map(&:candidates).flatten.uniq
  end

  def y_candidates
    (@game.tiles.map{ |tiles| tiles[y] }.flatten - [self]).map(&:candidates).flatten.uniq
  end

  def z_candidates
    x1 = x - x % 3
    y1 = y - y % 3

    ((x1..x1+2).map do |x|
      (y1..y1+2).map do |y|
        @game.tiles[x][y]
      end
    end.flatten - [self]).map(&:candidates).flatten.uniq
  end

  def range
    (1..9).to_a
  end
end

#game = SudokuGame.new("586374912 137952864 249816573 872543196 693781245 415629738 954237681 721468359 368195427")
game = SudokuGame.new("..6.7.9.. 1..9....4 ...8..5.3 87.5...9. ..37.1... 4...2.7.8 .5.2..6.. 7....8... 3..1..4..")
#game = SudokuGame.new("..6.7.9.. 1..9....4 ...8..5.3 87.5...9. ..37.1... 4...2.7.8 .5.2..6.. 7....8... 3..1..4..")
game.solve
