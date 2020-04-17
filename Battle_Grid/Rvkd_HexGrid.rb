# Scene used to test the features of the grid.
class Scene_TestGrid < Scene_Base

  def start
    super
    @hex_grid = HexGrid.new(@viewport)
    @counter = 0
  end

  def update
    super
    @counter += 1
    if @counter % 2000 == 1
      p(@hex_grid.all_tiles)
    end
  end

  def update_basic
    super
    check_input
  end

  def check_input
    @hex_grid.update
  end

end

class Game_Battler < Game_BattlerBase

  def set_grid_location(locations)
    @grid_coordinates = locations
  end

  def grid_row ; @grid_coordinates[0][0] end
  def grid_col ; @grid_coordinates[0][1] end
  def grid_coordinates ; @grid_coordinates end

end

class Game_Actor < Game_Battler
  def original_x
    unit_x = Revoked::Grid.position(*@grid_coordinates[0])[:x]
    unit_x += Revoked::Grid::UnitXOffset
    return unit_x
  end

  def original_y
    unit_y = Revoked::Grid.position(*@grid_coordinates[0])[:y]
    unit_y += Revoked::Grid::UnitYOffset
    return unit_y
  end

  def set_grid_coordinates(grid_row, grid_col)
    @grid_coordinates = [[grid_row, grid_col]]
  end
  def grid_coordinates ; @grid_coordinates[0] end
end

class Game_Enemy < Game_Battler

  def grid_size
    return @grid_size if @grid_size
    if $data_enemies[self.enemy_id].note =~ /<grid[\s_]*size:[\s]*(\d+)>/i
      case $1.to_i
      when 1 ; @grid_size = 1
      when 2 ; @grid_size = 2
      when 4 ; @grid_size = 4
      else ; @grid_size = 1
      end
    end
    return @grid_size
  end

  alias rvkd_hexgrid_gen_die die
  def die
    rvkd_hexgrid_gen_die
    PhaseTurn.remove_grid_unit(unit)
  end
  # def offset_x ; return @offset_x + Revoked::Grid::UnitXOffset ; end
  # def offset_y ; return @offset_y + Revoked::Grid::UnitYOffset ; end

end

# class RPG::Troop::Member
#   def x ; return @x + Revoked::Grid::UnitXOffset ; end
#   def y ; return @y + Revoked::Grid::UnitYOffset ; end
# end

class Game_System

  # attr_reader :party_positions
  # alias rvkd_hexgrid_gsy_initialize initialize
  # def initialize
  #   rvkd_hexgrid_gsy_initialize
  #   @party_positions = Revoked::Grid::DefaultPositions
  #   (1..@party_positions.size).each do |index|
  #     setup_party_position(index)
  #   end
  # end
  #
  # def update_party_positon(actor_id, position = [0,0])
  #   if @party_positons.any?{|x| p[0] != actor_id && x[1].eql?(position) }
  #     raise "Tried to update to an existing position"
  #   end
  #   @party_positions[actor_id] = position
  # end
  #
  # def setup_party_position(actor_id)
  #   row = @party_positions[actor_id][0]
  #   col = @party_positions[actor_id][1]
  #   msgbox_p($game_actors)
  #   $game_actors[actor_id].set_grid_coordinates(row, col)
  # end

end

class Game_Party

  attr_reader :grid_positions
  alias rvkd_hexgrid_gpa_initialize initialize
  def initialize
    rvkd_hexgrid_gpa_initialize
    setup_grid_positions
  end

  def setup_grid_positions
    @grid_positions = Revoked::Grid::DefaultPositions
    # @grid_positions.each do |actor_id, coordinates|
    #   $game_actors[actor_id].
    # end
  end

end

class Game_Troop

  # alias rvkd_hexgrid_gtr_setup setup
  # def setup(troop_id)
  #   rvkd_hexgrid_gtr_setup(troop_id)
  # end

  def setup_grid_positions(hex_grid)
    members.each do |member|
      # grid_height = 1 + 2 * (Revoked::Grid::RadiusY)
      # msgbox_p([member.screen_x, member.screen_y])
      x_pos = member.screen_x
      y_pos = member.screen_y
      xf = Revoked::Grid::TileWidth
      yf = Revoked::Grid::TileHeight

      mem_size = member.grid_size

      cds = []
      case mem_size
      when 1
        cds << Revoked::Grid.coordinates_from_pos(x_pos, y_pos)
      when 2
        cds << Revoked::Grid.coordinates_from_pos(x_pos - xf/2, y_pos)
        cds << Revoked::Grid.coordinates_from_pos(x_pos + xf/2, y_pos)
      when 4
        cds << Revoked::Grid.coordinates_from_pos(x_pos - xf/2, y_pos - yf/2)
        cds << Revoked::Grid.coordinates_from_pos(x_pos + xf/2, y_pos - yf/2)
        cds << Revoked::Grid.coordinates_from_pos(x_pos - xf/2, y_pos + yf/2)
        cds << Revoked::Grid.coordinates_from_pos(x_pos + xf/2, y_pos + yf/2)
      else
        cds.push(Revoked::Grid.coordinates_from_pos(x_pos, y_pos))
      end
      sum_x = 0
      sum_y = 0
      p(cds)
      cds.each do |pair|
        pos = Revoked::Grid.position(*pair)
        sum_x += pos[:x]
        sum_y += pos[:y]
      end

      member.screen_x = sum_x / cds.size + Revoked::Grid::UnitXOffset
      member.screen_y = sum_y / cds.size + Revoked::Grid::UnitYOffset
      member.set_grid_location(cds)
      p(cds.size)
      containing_tiles = hex_grid.tiles_from_coordinates(cds)
      containing_tiles.each {|tile| tile.add_unit(member)}
    end
  end

end

#------------------------------------------------------------------------------
# ** Spriteset_Battle
#==============================================================================
class Spriteset_Battle

  # alias rvkd_hexgrid_spb_initialize initialize
  # def initialize
  #   create_grid
  #   rvkd_hexgrid_spb_initialize
  # end

  def create_grid
    @battle_grid = HexGrid.new(@viewport0)
    return @battle_grid
  end

  alias rvkd_hexgrid_spb_create_viewports create_viewports
  def create_viewports
    rvkd_hexgrid_spb_create_viewports
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

  alias rvkd_hexgrid_spb_update_viewports update_viewports
  def update_viewports
    rvkd_hexgrid_spb_update_viewports
    @viewport0.update
  end

  def dispose_grid
    @battle_grid.dispose_grid
  end

end

#------------------------------------------------------------------------------
# ** HexGrid - Class that stores and manages the grid.
#==============================================================================
class HexGrid

  # def test_m
  #   if Input.repeat?(:C)
  #     n = @grid[@cursor[0]][@cursor[1]].neighbours_dir([1])
  #     n.each {|t| t.select_tile if t}
  #   elsif Input.repeat?(:B)
  #     n = @grid[@cursor[0]][@cursor[1]].neighbours_dir([2])
  #     n.each {|t| t.deselect_tile if t}
  #   end
  # end

  def initialize(viewport)
    p("Initializing")
    create_tiles
    #create_links
    @cursor = [0,0]
    @cursor_area = [0,0]
    @viewport = viewport
    @sel_movable = []
    @sel_available = []
    @sel_potential = []
  end

  # Called by the scene every frame.
  def update
    if cursor_movable?
      process_cursor_move
    end
    # if @to_cancel
    #   reset_tiles(all_tiles)
    #   @to_cancel = false
    # end
    # if @to_dim != nil
    #   make_dim(all_tiles - @to_dim)
    #   @to_dim = nil
    # end
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
    @tilelist = []
    radius_x = Revoked::Grid::RadiusX
    radius_y = Revoked::Grid::RadiusY

    (-radius_y..radius_y).each do |row|
      @grid[row] = {}
      left_ind  = row < 0 ? -radius_x - row : -radius_x
      right_ind = row > 0 ? radius_x - row : radius_x
      (left_ind..right_ind).each { |col|
        @grid[row][col] = HexTile.new(col, row, @viewport)
        @tilelist.push(@grid[row][col])
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
    #test_m

    if Input.repeat?(:UP)
      # if Input.press?(:left)
        cursor_up(:left)
      # elsif Input.repeat?(:right)
      #   cursor_up(:right)
      # end
      #Input.dir8 == 9 ? cursor_up(:right) : cursor_up(:left)
    elsif Input.repeat?(:DOWN)
      # if Input.repeat?(:left)
      #   cursor_down(:left)
      # elsif Input.repeat?(:right)
        cursor_down(:right)
      # end
      #Input.dir8 == 1 ? cursor_down(:left) : cursor_down(:right)
    elsif Input.repeat?(:LEFT)
      cursor_left
    elsif Input.repeat?(:RIGHT)
      cursor_right
    end

    unless @cursor.eql?(last)
      Sound.play_grid_move
      get(*last).deselect_tile
      get(*@cursor).select_tile
    end
  end

  # Move up-left by default if no direction is specified.
  def cursor_up(direction = :left)
    if direction == :right
      # Move to the top right.
      if @grid[@cursor[0]-1] &&
        @sel_movable.include?(@grid[@cursor[0]-1][@cursor[1]+1])
        @cursor[0] = @cursor[0]-1
        @cursor[1] = @cursor[1]+1
      elsif @grid[@cursor[0]-1] &&
        @sel_movable.include?(@grid[@cursor[0]-1][@cursor[1]])
        # Default to the top left if it exists and there is no top right tile.
        @cursor[0] = @cursor[0]-1
      else
        Sound.play_grid_error
      end
    elsif direction == :left # Move to the top left.
      if @grid[@cursor[0]-1] &&
        @sel_movable.include?(@grid[@cursor[0]-1][@cursor[1]])
        @cursor[0] = @cursor[0]-1
      elsif @grid[@cursor[0]-1] &&
        @sel_movable.include?(@grid[@cursor[0]-1][@cursor[1]+1])
        # Default to the top right if it exists and there is no top left tile.
        @cursor[0] = @cursor[0]-1
        @cursor[1] = @cursor[1]+1
      else
        Sound.play_grid_error
      end
    end
  end

  # Move down-right by default if no direction is specified.
  def cursor_down(direction = :right)
    if direction == :left
      # Move to the bottom left.
      if @grid[@cursor[0]+1] &&
        @sel_movable.include?(@grid[@cursor[0]+1][@cursor[1]-1])
        @cursor[0] = @cursor[0]+1
        @cursor[1] = @cursor[1]-1
      elsif @grid[@cursor[0]+1] &&
        @sel_movable.include?(@grid[@cursor[0]+1][@cursor[1]])
        # Default to the bottom right if it exists and there is no bottom left.
        @cursor[0] = @cursor[0]+1
      else
        Sound.play_grid_error
      end
    elsif direction == :right # Move to the bottom right.
      if @grid[@cursor[0]+1] &&
        @sel_movable.include?(@grid[@cursor[0]+1][@cursor[1]])
        @cursor[0] = @cursor[0]+1
      elsif @grid[@cursor[0]+1] &&
        @sel_movable.include?(@grid[@cursor[0]+1][@cursor[1]-1])
        # Default to the bottom left if it exists and there is no bottom right.
        @cursor[0] = @cursor[0]+1
        @cursor[1] = @cursor[1]-1
      else
        Sound.play_grid_error
      end
    end
  end

  def cursor_left
    if @sel_movable.include?(@grid[@cursor[0]][@cursor[1]-1])
      @cursor[1] = @cursor[1]-1
    else
      Sound.play_grid_error
    end
  end

  def cursor_right
    if @sel_movable.include?(@grid[@cursor[0]][@cursor[1]+1])
      @cursor[1] = @cursor[1]+1
    else
      Sound.play_grid_error
    end
  end

  # Return an array of tiles given a 2D array of coordinates. [[y,x]]
  def tiles_from_coordinates(region = [])
    result = []
    region.each {|pair|
      next unless @grid[pair[0]] && @grid[pair[0]][pair[1]]
      result.push(@grid[pair[0]][pair[1]])
    }
    return result
  end

  def selected_units
  end

  #----------------------------------------------------------------------------
  # Tile selection and highlighting for UI
  #----------------------------------------------------------------------------
  def get(row, col)
    return @grid[row][col]
  end

  def set_origin(row, col)
    @cursor = [row, col]
    @grid[row][col].select_tile
  end

  def set_cursor_tile(tile)
    @cursor = tile.coordinates_rc
    tile.select_tile
  end

  def all_tiles
    @tilelist
  end

  def setup_target_selection(cursor_origin, available, area, potential = [])
    reset_tiles(@tilelist)
    dim_tiles = @tilelist - (available + potential)
    make_available(available)
    make_potential(potential)
    make_dim(dim_tiles)

    $game_troop.members.each {|mem| msgbox_p(mem.grid_coordinates) }
    set_cursor_tile(cursor_origin)
    @sel_available = available
    @sel_potential = potential
    @sel_movable = available + potential
  end

  def cancel_target_selection(reselect_actor = nil)
    reset_tiles(all_tiles)
    #@grid[@cursor[0]][@cursor[1]].select_tile
    msgbox_p(reselect_actor ? reselect_actor.grid_coordinates : "nil")
    set_origin(*reselect_actor.grid_coordinates) unless reselect_actor.nil?
    @sel_available.clear
    @sel_potential.clear
    @sel_movable = all_tiles
  end

  def make_available(tiles) ; tiles.each {|t| t.opacity_available_tile } end
  def make_potential(tiles) ; tiles.each {|t| t.opacity_potential_tile } end
  def make_dim(tiles)       ; tiles.each {|t| t.opacity_dim_tile } end
  def reset_tiles(tiles)
    tiles.each do |t|
      t.reset_opacity
      t.deselect_tile
    end
  end

  #----------------------------------------------------------------------------
  # Grid unit handling
  #----------------------------------------------------------------------------
  def remove_unit(unit)
    all_tiles.each {|tile| tile.remove_unit(unit) }
  end


end # HexGrid

#------------------------------------------------------------------------------
# HexTile
#------------------------------------------------------------------------------
class HexTile

  attr_reader :neighbours
  attr_reader :unit_contents
  def initialize(x_index, y_index, viewport)
    @viewport = viewport
    @floor_sprite = Sprite.new(@viewport)
    @floor_sprite.bitmap = Cache.grid("htile_neutral")
    @floor_sprite.opacity = 128

    @select_sprite = Sprite.new(@viewport)
    @select_sprite.bitmap = Cache.grid("htile_glow")
    @select_sprite.opacity = 0

    # Place tile sprites.
    position = Revoked::Grid.position(y_index, x_index)
    @floor_sprite.x = position[:x]
    @floor_sprite.y = position[:y]
    @floor_sprite.z = 0
    @select_sprite.x = @floor_sprite.x
    @select_sprite.y = @floor_sprite.y
    @select_sprite.z = 0

    # initialize fields
    @ind_x = x_index
    @ind_y = y_index
    @selected = false
    # right, top_right, top_left, left, bottom_left, bottom_right
    @neighbours = [nil,nil,nil,nil,nil,nil]
    # keep track of units on the tile.
    clear_units
    refresh
  end

  # Update all sprites
  def refresh
    @floor_sprite.update
    @select_sprite.update if @selected
  end

  # Free all sprites
  def dispose
    @unit_contents.clear
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
  def coordinates_xy ; return [@ind_x, @ind_y] end
  def coordinates_rc ; return [@ind_y, @ind_x] end

  #------------------------------\
  # Tile colouring and appearance \--------------------------------------------
  # Set colour to claimed scheme ----------------------------------------------
  def ally_tile    ; @floor_sprite.color.set(64,160,224,192) end
  def enemy_tile   ; @floor_sprite.color.set(224,128,128,192) end
  def neutral_tile ; @floor_sprite.color.set(224,224,224,224) end

  # Highlight the unit receiving a command.
  def select_input_unit
    select_tile
  end

  # Highlight graphic
  def select_tile
    @selected = true
    @select_sprite.bitmap = Cache.grid("htile_glow")
    @select_sprite.opacity = 200
    refresh
  end

  def deselect_tile
    @selected = false
    @select_sprite.opacity = 0
    refresh
  end

  # Secondary tile from main tile (i.e., area of effect radius)
  def set_area_effect_tile
    @selected = true
    @select_sprite.bitmap = Cache.grid("htile_glow_s")
    @select_sprite.opacity = 200
    refresh
  end

  def reset_area_effect_tile
    @selected = false
    @select_sprite.opacity = 0
    refresh
  end

  # Brighter to indicate that the cursor can move there.
  def opacity_available_tile ; @floor_sprite.opacity = 200 end
  # Slightly brighter to indicate that this space can be selected with a move.
  def opacity_potential_tile ; @floor_sprite.opacity = 150 end
  # reduce the opacity of the tile to emphasize other tiles.
  def opacity_dim_tile ; @floor_sprite.opacity = 64 end
  def reset_opacity ; @floor_sprite.opacity = 128 end

  #----------------------------------------------------------------------------
  # Area building functions
  #----------------------------------------------------------------------------
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

  #----------------------------------------------------------------------------
  # Target functions
  #----------------------------------------------------------------------------
  def add_unit(unit)    ; @unit_contents << unit end
  def remove_unit(unit) ; @unit_contents -= [unit] end
  def clear_units       ; @unit_contents = [] end

end # HexTile

#------------------------------------------------------------------------------
# Grid Sprite
#------------------------------------------------------------------------------
