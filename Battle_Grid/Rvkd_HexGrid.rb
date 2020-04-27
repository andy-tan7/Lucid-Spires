
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

end

class Game_Party

  attr_reader :grid_positions
  alias rvkd_hexgrid_gpa_initialize initialize
  def initialize
    rvkd_hexgrid_gpa_initialize
    initialize_grid_variable
  end

  def initialize_grid_variable
    @grid_positions = Revoked::Grid::DefaultPositions
  end

  def setup_grid_positions(hex_grid)
    members.each do |member|
      coordinates = member.grid_coordinates
      hex_grid.get(*coordinates).add_unit(member)
    end
  end

end

class Game_Troop

  def setup_grid_positions(hex_grid)
    members.each do |member|
      # grid_height = 1 + 2 * (Revoked::Grid::RadiusY)
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
      cds.each do |pair|
        pos = Revoked::Grid.position(*pair)
        sum_x += pos[:x]
        sum_y += pos[:y]
      end

      member.screen_x = sum_x / cds.size + Revoked::Grid::UnitXOffset
      member.screen_y = sum_y / cds.size + Revoked::Grid::UnitYOffset
      member.set_grid_location(cds)
      containing_tiles = hex_grid.tiles_from_coordinates(cds)
      containing_tiles.each {|tile| tile.add_unit(member)}
    end
  end

end

#------------------------------------------------------------------------------
# ** Spriteset_Battle
#==============================================================================
class Spriteset_Battle

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

  def initialize(viewport)
    create_tiles
    #create_links
    @cursor = [0,0]
    @cursor_area = [0,0]
    @adapt_dir = {:up => nil, :down => nil, :actor_row => 0}

    @viewport = viewport
    @sel_movable = []
    @sel_available = []
    @sel_potential = []
    @sel_area = []
    @area_item = nil
    @phase = :idle  # :idle, :input, :selection
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
    @tilelist = []
    @grid_arrow = GridArrow.new(@viewport)

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

  def dispose_grid
    @grid.each {|tile| tile.dispose }
  end

  def cursor_movable? ; @phase == :selection ; end

  # Cause the cursor to "bend" around the actor making an input.
  def setup_adaptive_cursor
    @adapt_dir[:actor_row] = BattleManager.actor.grid_coordinates[0] rescue 0
    update_adaptive_cursor
  end

  def update_adaptive_cursor
    @adapt_dir[:up] = @cursor[0] > @adapt_dir[:actor_row] ? :left : :right
    @adapt_dir[:down] = @cursor[0] < @adapt_dir[:actor_row] ? :left : :right
  end

  # :input, :selection, :idle
  def set_phase(phase)
    case phase
    when :input
      @phase = :input
      set_origin(*BattleManager.actor.grid_coordinates)
    when :selection
      @phase = :selection
      setup_adaptive_cursor
    when :idle
      @phase = :idle
    end
  end

  # Handle directional movement on the grid.
  def process_cursor_move
    return unless cursor_movable?
    last = @cursor.dup

    if Input.repeat?(:UP)
      cursor_up(@adapt_dir[:up])
    elsif Input.repeat?(:DOWN)
      cursor_down(@adapt_dir[:down])
    elsif Input.repeat?(:LEFT)
      cursor_left
    elsif Input.repeat?(:RIGHT)
      cursor_right
    end

    unless @cursor.eql?(last)
      Sound.play_grid_move
      cursor_deselect(get(*last))
      recalculate_area
      cursor_select(get(*@cursor))
      update_adaptive_cursor
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
      next unless @grid[pair[0]] && get(*pair)
      result.push(get(*pair))
    }
    return result
  end

  #----------------------------------------------------------------------------
  # Tile selection and highlighting for UI
  #----------------------------------------------------------------------------
  def get(row, col)
    return @grid[row][col]
  end
  def all_tiles ; @tilelist ; end

  def set_origin(row, col)
    @cursor = [row, col]
    cursor_select(get(*@cursor))
  end

  def set_cursor_tile(tile)
    @cursor = tile.coordinates_rc
    cursor_select(tile)
  end

  def set_area_item(item) ; @area_item = item ; end
  def recalculate_area
    return if @area_item.nil? || @sel_area.empty?
    unhighlight_for_area(@sel_area)
    @sel_area = Revoked::Grid::make_area_tiles(self, get(*@cursor), @area_item)
  end

  def setup_target_selection(cursor_origin, available, potential, area)
    reset_tiles(@tilelist)
    dim_tiles = @tilelist - (available + potential)
    make_available(available)
    make_potential(potential)
    make_dim(dim_tiles)

    set_cursor_tile(cursor_origin)
    @sel_area = area
    @sel_available = available
    @sel_potential = potential
    @sel_movable = available + potential
  end

  def cancel_target_selection
    reset_tiles(all_tiles)
    @area_item = nil
    @sel_area.clear
    @sel_available.clear
    @sel_potential.clear
    @sel_movable = all_tiles
  end

  # Sprite changes
  def cursor_select(tile) ; tile.select_tile end
  def cursor_deselect(tile)
    tile.deselect_tile
    tile.unlight_area
  end

  def highlight_for_area(t)
    t.light_area if t.is_a?(HexTile) && !t.equal?(get(*@cursor))
    t.each {|h| h.light_area if !h.equal?(get(*@cursor))} if t.is_a?(Array)
  end
  def unhighlight_for_area(t)
    t.light_area if t.is_a?(HexTile) && !t.equal?(get(*@cursor))
    t.each {|h| h.unlight_area if !h.equal?(get(*@cursor))} if t.is_a?(Array)
  end

  # Opacity changes
  def make_available(tiles) ; tiles.each {|t| t.opacity_available_tile } end
  def make_potential(tiles) ; tiles.each {|t| t.opacity_potential_tile } end
  def make_dim(tiles)       ; tiles.each {|t| t.opacity_dim_tile } end
  def reset_tiles(tiles)
    tiles.each do |t|
      t.reset_opacity
      t.deselect_tile
      t.unlight_area
    end
  end

  #----------------------------------------------------------------------------
  # Grid unit handling
  #----------------------------------------------------------------------------
  def remove_unit(unit)
    all_tiles.each {|tile| tile.remove_unit(unit) }
  end

  def get_selected_units
    units = []
    @sel_area.each {|tile| units.push(tile.unit_contents) }
    units.flatten!
    msgbox_p(units.collect {|u| u.name})
    units.uniq!
    return units
  end

  def copy_selected_area
    return @sel_area.dup
  end

end # HexGrid

#------------------------------------------------------------------------------
# HexTile
#------------------------------------------------------------------------------
class HexTile

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
  def light_area
    @selected = true
    @select_sprite.bitmap = Cache.grid("htile_glow_s")
    @select_sprite.opacity = 200
    refresh
  end

  def unlight_area
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
  # Target functions
  #----------------------------------------------------------------------------
  def add_unit(unit)    ; @unit_contents << unit end
  def remove_unit(unit) ; @unit_contents -= [unit] end
  def clear_units       ; @unit_contents = [] end

  def occupied? ; return !@unit_contents.nil? && !@unit_contents.empty? ; end

end # HexTile

#------------------------------------------------------------------------------
# Grid Arrow
#------------------------------------------------------------------------------
class GridArrow

  def initialize(viewport)
    @viewport = viewport
    @arrow = Sprite.new(@viewport)
    @arrow.bitmap = Cache.grid("arrow_1")
    set_opacity(0)

    @index = 1
  end

  def update_position(row, col)
    pos = Revoked::Grid.position(row, col)
    self.x = pos[:x]
    self.y = pos[:y]
  end

  def update_index
    @index += 1
    @index = 1 if @index > 30
    self.bitmap = Cache.grid("arrow_#{@index/6}") if @index % 6 == 0
  end

  def set_opacity(opac)
    @arrow.opacity = opac
    @visible = opac == 0 ? false : true
  end

end
