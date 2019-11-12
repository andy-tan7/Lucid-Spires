# hex grid
module Revoked

  module Grid
    RadiusY = 1
    RadiusX = 4
    MaxHeight = 1 + 2 * RadiusY
    MaxWidth  = 1 + 2 * RadiusX

    TileHeight = 50
    TileWidth  = 58
  end

end

module Cache
  def self.grid(filename)
    load_bitmap("Graphics/Grid/", filename)
  end
end

class Scene_TestGrid < Scene_Base

  def start
    super
    @hex_grid = HexGrid.new
  end

  def update
    super
  end

  def update_basic
    super
    check_input
  end

  def check_input
    @hex_grid.update
  end



end


class HexGrid

  def initialize
    create_tiles
    create_links
    @cursor = [0,0]
    @grid[@cursor[0]][@cursor[1]].select_tile
  end

  def test_m
    @grid[@cursor[0]][@cursor[1]].neighbours.each {|tile| tile.select_tile if tile }
  end

  def update
    process_cursor_move
  end

  def create_tiles
    radius_x = Revoked::Grid::RadiusX
    radius_y = Revoked::Grid::RadiusY
    @grid = {}
    (-radius_y..radius_y).each do |r|
      @grid[r] = {}
      left_ind  = r < 0 ? -radius_x - r : -radius_x
      right_ind = r > 0 ? radius_x - r : radius_x
      (left_ind..right_ind).each {|c| @grid[r][c] = HexTile.new(c,r)}
    end
    # -1, 0, 1 y indices
    # -3 to 4 x for row y=-1
    # -4 to 4 x for row y=0
    # -4 to 3 x for row y=1

  end

  def create_links
    @grid.keys.each do |row|
      @grid[row].keys.each do |tile|
        @grid[row][tile].neighbours[0] = @grid[row][tile + 1]
        @grid[row][tile].neighbours[3] = @grid[row][tile - 1]

      end
    end
  end

  def cursor_movable?
    return true
  end

  def process_cursor_move
    return unless cursor_movable?
    last = @cursor.dup
    # case Input.dir8
    # when 1; cursor_down(:left) if Input.repeat?(:DOWN) || Input.repeat?(:LEFT)
    # #when 2; cursor_down(@last_dir_mode) if Input.repeat?(:DOWN)
    # when 3; cursor_down(:right) if Input.repeat?(:DOWN) || Input.repeat?(:RIGHT)
    # when 4; cursor_left if Input.repeat?(:LEFT)
    # when 6; cursor_right if Input.repeat?(:RIGHT)
    # when 7; cursor_up(:left) if Input.repeat?(:UP) || Input.repeat?(:LEFT)
    # #when 8; cursor_up(@last_dir_mode) if Input.repeat?(:UP)
    # when 9; cursor_up(:right) if Input.repeat?(:UP) || Input.repeat?(:RIGHT)
    # end

    if Input.repeat?(:UP)
      #(last[0] % 2 == 0 ? cursor_up(:right) : cursor_up(:left))
      cursor_up
    elsif Input.repeat?(:DOWN)
      #(last[0] % 2 == 0 ? cursor_down(:right) : cursor_down(:left))
      cursor_down
    elsif Input.repeat?(:LEFT)
      cursor_left
    elsif Input.repeat?(:RIGHT)
      cursor_right
    end
    unless @cursor.eql?(last)
      Sound.play_cursor
      @grid[last[0]][last[1]].deselect_tile
      @grid[@cursor[0]][@cursor[1]].select_tile
    end
  end

  # Move up-left by default if no direction is specified.
  def cursor_up(direction = :left)
    if direction == :right
      if @grid[@cursor[0]-1] && @grid[@cursor[0]-1][@cursor[1]+1]
        @cursor[0] = @cursor[0]-1; @cursor[1] = @cursor[1]+1
      end
    else
      if @grid[@cursor[0]-1] && @grid[@cursor[0]-1][@cursor[1]]
        @cursor[0] = @cursor[0]-1
      else
        if @grid[@cursor[0]-1] && @grid[@cursor[0]-1][@cursor[1]+1]
          @cursor[0] = @cursor[0]-1; @cursor[1] = @cursor[1]+1
        end
      end
    end
  end

  # Move down-right by default if no direction is specified.
  def cursor_down(direction = :right)
    if direction == :left
      p("DL #{@cursor}")
      if @grid[@cursor[0]+1] && @grid[@cursor[0]+1][@cursor[1]-1]
        @cursor[0] = @cursor[0]+1
        @cursor[1] = @cursor[1]-1
      end
    else
      p("DR #{@cursor}")
      if @grid[@cursor[0]+1] && @grid[@cursor[0]+1][@cursor[1]]
        @cursor[0] = @cursor[0]+1
      else
        if @grid[@cursor[0]+1] && @grid[@cursor[0]+1][@cursor[1]-1]
          @cursor[0] = @cursor[0]+1
          @cursor[1] = @cursor[1]-1
        end
      end
    end
  end

  def cursor_left
    p("L #{@cursor}")
    @cursor[1] = @cursor[1]-1 unless @grid[@cursor[0]][@cursor[1]-1].nil?
    @last_dir_mode = :left
  end

  def cursor_right
    p("R #{@cursor}")
    @cursor[1] = @cursor[1]+1 unless @grid[@cursor[0]][@cursor[1]+1].nil?
    @last_dir_mode = :right
  end


end

#------------------------------------------------------------------------------
# HexTile
#------------------------------------------------------------------------------
class HexTile

  attr_reader :neighbours
  def initialize(x,y)
    @floor_sprite = Sprite.new(@viewport)
    @floor_sprite.bitmap = Cache.grid("htile_neutral")

    @select_sprite = Sprite.new(@viewport)
    @select_sprite.bitmap = Cache.grid("htile_glow")


    @floor_sprite.x = Graphics.width / 2 + ((x+0.5*y) * Revoked::Grid::TileWidth).to_i
    @floor_sprite.y = Graphics.height / 2 + y * Revoked::Grid::TileHeight
    @select_sprite.x = @floor_sprite.x
    @select_sprite.y = @floor_sprite.y

    # offset_x = (y % 2 != 0) ? Revoked::Grid::TileWidth / 2 : 0
    # @floor_sprite.x = Graphics.width / 2 + Revoked::Grid::TileWidth * x + offset_x
    # @floor_sprite.y = Graphics.height / 2 + Revoked::Grid::TileHeight * y
    @floor_sprite.opacity = 255
    @select_sprite.opacity = 0

    @ind_x = x
    @ind_y = y
    @selected = false
    @neighbours = [nil,nil,nil,nil,nil,nil]
    # right, bottom_right, bottom_left, left, top_left, top_right

    refresh
  end

  def x=(x_var)
    @x = x_var
    @floor_sprite.x = x_var
    @select_sprite.x = x_var
  end

  def y=(y_var)
    @y = y_var
    @floor_sprite.y = y_var
    @select_sprite.y = x_var
  end

  def make_neighbour(index, neighbour)
    @neighbours[index] ||= neighbour
  end

  def coordinates
    return [@ind_x,@ind_y]
  end

  def select_tile
    @selected = true
    @select_sprite.opacity = 200
    refresh
  end

  def deselect_tile
    @selected = false
    @select_sprite.opacity = 0
    refresh
  end

  def refresh
    @floor_sprite.update
    @select_sprite.update
  end

end

#------------------------------------------------------------------------------
# Grid Sprite
#------------------------------------------------------------------------------
