# Scene used to test the features of the grid.
class Scene_TestGrid < Scene_Base

  def start
    super
    @hex_grid = HexGrid.new(@viewport)
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

class Game_Actor
  def original_x
    unit_x = Revoked::Grid.position(0,0)[:x]
    unit_x += Revoked::Grid::UnitXOffset
    unit_x
  end
  def original_y
    unit_y = Revoked::Grid.position(0,0)[:y]
    unit_y += Revoked::Grid::UnitYOffset
    unit_y
  end
end

#------------------------------------------------------------------------------
# ** Game_Temp
#==============================================================================
class Game_Temp
  attr_accessor :grid
end

#------------------------------------------------------------------------------
# ** Spriteset_Battle
#==============================================================================
class Spriteset_Battle

  alias rvkd_grid_spriteset_battle_initialize initialize
  def initialize
    create_grid
    rvkd_grid_spriteset_battle_initialize
  end

  def create_grid
    $game_temp.grid = HexGrid.new(@viewport0)
  end

  alias rvkd_grid_spriteset_battle_create_viewports create_viewports
  def create_viewports
    rvkd_grid_spriteset_battle_create_viewports
    @viewport0 = Viewport.new
    @viewport0.z = 0
    @viewport1.z = 25
  end

  # override: create_battleback1
  def create_battleback1
    @back1_sprite = Sprite.new(@viewport0)
    @back1_sprite.bitmap = battleback1_bitmap
    @back1_sprite.z = 0
    #center_sprite(@back1_sprite)
  end

  alias rvkd_grid_spriteset_battle_update_viewports update_viewports
  def update_viewports
    rvkd_grid_spriteset_battle_update_viewports
    @viewport0.update
  end

  def dispose_grid
    $game_temp.grid.dispose_grid
  end

end

#------------------------------------------------------------------------------
# ** HexGrid - Class that stores and manages the grid.
#==============================================================================
class HexGrid

  def test_m
    if Input.repeat?(:C)
      n = @grid[@cursor[0]][@cursor[1]].neighbours_dir([1])
      n.each {|t| t.select_tile if t}
    elsif Input.repeat?(:B)
      n = @grid[@cursor[0]][@cursor[1]].neighbours_dir([2])
      n.each {|t| t.deselect_tile if t}
    end
  end

  def initialize(viewport)
    create_tiles
    create_links
    @cursor = [0,0]
    @grid[@cursor[0]][@cursor[1]].select_tile
    @viewport = viewport
    @grid[1][1].ally_tile
    @grid[0][1].neutral_tile
    @grid[-1][1].enemy_tile
  end

  # Called by the scene every frame.
  def update
    if cursor_movable?
      process_cursor_move
    end
  end

  # Default -------------------------------------------------------------------
  # -1, 0, 1 y indices
  # -3 to 4 x for row y=-1
  # -4 to 4 x for row y=0
  # -4 to 3 x for row y=1
  def create_tiles
    # Contain the grid in a hash with int keys to put the origin (0,0) in the
    # grid center and allow for "negative indices" relative to the origin.
    @grid = {}
    radius_x = Revoked::Grid::RadiusX
    radius_y = Revoked::Grid::RadiusY

    (-radius_y..radius_y).each do |row|
      @grid[row] = {}
      left_ind  = row < 0 ? -radius_x - row : -radius_x
      right_ind = row > 0 ? radius_x - row : radius_x
      (left_ind..right_ind).each { |col|
        @grid[row][col] = HexTile.new(col, row, @viewport)
      }
    end
  end

  #----------------------------------------------------------------------------
  # create_links
  #  2 1     \       make a reference to all neighbours for each node.
  # 3 x 0  ---\---
  #  4 5       \     note: y axis is slanted to the left.
  #----------------------------------------------------------------------------
  def create_links
    # The grid keys -> row indexes (-radius_y, ... 0, ... radius_y)
    # grid[row] keys -> column indexes (-radius_x, ... 0, ... radius_x)
    @grid.keys.each { |row|
      @grid[row].keys.each { |col|
        tile = @grid[row][col]
        tile.make_neighbour(0, @grid[row][col + 1])                     # r
        tile.make_neighbour(1, @grid[row - 1][col + 1]) if @grid[row-1] # tr
        tile.make_neighbour(2, @grid[row - 1][col]) if @grid[row-1]     # tl
        tile.make_neighbour(3, @grid[row][col - 1])                     # l
        tile.make_neighbour(4, @grid[row + 1][col - 1]) if @grid[row+1] # bl
        tile.make_neighbour(5, @grid[row + 1][col]) if @grid[row+1]     # br
      }
    }
  end

  def dispose_grid
    @grid.each {|tile| tile.dispose }
  end

  def cursor_movable?
    return true
  end

  # Handle directional movement on the grid.
  def process_cursor_move
    return unless cursor_movable?
    last = @cursor.dup
    test_m

    if Input.repeat?(:UP)
      Input.dir8 == 9 ? cursor_up(:right) : cursor_up(:left)
    elsif Input.repeat?(:DOWN)
      Input.dir8 == 1 ? cursor_down(:left) : cursor_down(:right)
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
      # Move to the top right.
      if @grid[@cursor[0]-1] && @grid[@cursor[0]-1][@cursor[1]+1]
        @cursor[0] = @cursor[0]-1
        @cursor[1] = @cursor[1]+1
      elsif @grid[@cursor[0]-1] && @grid[@cursor[0]-1][@cursor[1]]
        # Default to the top left if it exists and there is no top right tile.
        @cursor[0] = @cursor[0]-1
      end
    elsif direction == :left # Move to the top left.
      if @grid[@cursor[0]-1] && @grid[@cursor[0]-1][@cursor[1]]
        @cursor[0] = @cursor[0]-1
      elsif @grid[@cursor[0]-1] && @grid[@cursor[0]-1][@cursor[1]+1]
        # Default to the top right if it exists and there is no top left tile.
        @cursor[0] = @cursor[0]-1
        @cursor[1] = @cursor[1]+1
      end
    end
  end

  # Move down-right by default if no direction is specified.
  def cursor_down(direction = :right)
    if direction == :left
      # Move to the bottom left.
      if @grid[@cursor[0]+1] && @grid[@cursor[0]+1][@cursor[1]-1]
        @cursor[0] = @cursor[0]+1
        @cursor[1] = @cursor[1]-1
      elsif @grid[@cursor[0]+1] && @grid[@cursor[0]+1][@cursor[1]]
        # Default to the bottom right if it exists and there is no bottom left.
        @cursor[0] = @cursor[0]+1
      end
    elsif direction == :right # Move to the bottom right.
      if @grid[@cursor[0]+1] && @grid[@cursor[0]+1][@cursor[1]]
        @cursor[0] = @cursor[0]+1
      elsif @grid[@cursor[0]+1] && @grid[@cursor[0]+1][@cursor[1]-1]
        # Default to the bottom left if it exists and there is no bottom right.
        @cursor[0] = @cursor[0]+1
        @cursor[1] = @cursor[1]-1
      end
    end
  end

  def cursor_left
    @cursor[1] = @cursor[1]-1 unless @grid[@cursor[0]][@cursor[1]-1].nil?
  end

  def cursor_right
    @cursor[1] = @cursor[1]+1 unless @grid[@cursor[0]][@cursor[1]+1].nil?
  end

end # HexGrid

#------------------------------------------------------------------------------
# HexTile
#------------------------------------------------------------------------------
class HexTile

  attr_reader :neighbours
  def initialize(x_index, y_index, viewport)
    @viewport = viewport
    @floor_sprite = Sprite.new(@viewport)
    @floor_sprite.bitmap = Cache.grid("htile_neutral")

    @select_sprite = Sprite.new(@viewport)
    @select_sprite.bitmap = Cache.grid("htile_glow")

    # Place tile sprites.
    position = Revoked::Grid.position(x_index, y_index)
    @floor_sprite.x = position[:x]
    @floor_sprite.y = position[:y]
    @floor_sprite.z = 0
    @select_sprite.x = @floor_sprite.x
    @select_sprite.y = @floor_sprite.y
    @select_sprite.z = 0
    @floor_sprite.opacity = 192
    @select_sprite.opacity = 0

    # initialize fields
    @ind_x = x_index
    @ind_y = y_index
    @selected = false
    # right, top_right, top_left, left, bottom_left, bottom_right
    @neighbours = [nil,nil,nil,nil,nil,nil]
    refresh
  end

  # Update all sprites
  def refresh
    @floor_sprite.update
    @select_sprite.update if @selected
  end

  # Free all sprites
  def dispose
    @floor_sprite.dispose
    @select_sprite.dispose
  end

  # Set neighbour array
  def make_neighbour(index, neighbour_tile)
    @neighbours[index] ||= neighbour_tile
  end

  # Override x=
  def x=(x_var)
    @x = x_var
    @floor_sprite.x = x_var
    @select_sprite.x = x_var
  end

  # Override y=
  def y=(y_var)
    @y = y_var
    @floor_sprite.y = y_var
    @select_sprite.y = x_var
  end

  # Get [x,y] hash keys for the grid
  def coordinates
    return [@ind_x,@ind_y]
  end

  def ally_tile
    @floor_sprite.color.set(64,160,224,192)
  end

  def enemy_tile
    @floor_sprite.color.set(224,128,128,192)
  end

  def neutral_tile
    @floor_sprite.color.set(224,224,224,192)
  end

  # Highlight graphic
  def select_tile
    @selected = true
    @select_sprite.opacity = 200
    refresh
  end

  # Regular graphic
  def deselect_tile
    @selected = false
    @select_sprite.opacity = 0
    refresh
  end

  # Get neighbours in specified direction (e.g., not behind character)
  def neighbours_dir(directions = [:left])
    # right, top_right, top_left, left, bottom_left, bottom_right
    result = []
    puts (directions)
    directions.each do |dir|
      case dir
      when :right
        result |= [@neighbours[0]]
      when :top_right
        result |= [@neighbours[1]]
      when :top_left
        result |= [@neighbours[2]]
      when :left
        result |= [@neighbours[3]]
      when :bottom_left
        result |= [@neighbours[4]]
      when :bottom_right
        result |= [@neighbours[5]]
      end
    end
    return result.uniq.compact
  end

end # HexTile

#------------------------------------------------------------------------------
# Grid Sprite
#------------------------------------------------------------------------------
