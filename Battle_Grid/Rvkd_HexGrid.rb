#==============================================================================
# Grid Shift Phase Turn Battle System - Hex Grid
#------------------------------------------------------------------------------
#  This script creates and maintains the hex grid functionality in battle.
#==============================================================================
# ■ HexGrid - Class that stores and manages the grid.
#==============================================================================
class HexGrid
  #---------------------------------------------------------------------------
  # * Object Initialization
  #---------------------------------------------------------------------------
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
  #---------------------------------------------------------------------------
  # Generate and store the individual hex grid tile objects.
  #---------------------------------------------------------------------------
  # Default:
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
  #---------------------------------------------------------------------------
  # * Free
  #---------------------------------------------------------------------------
  def dispose_grid
    @grid.each_value {|row| row.each_value {|tile| tile.dispose }}
  end

  def cursor_movable? ; @phase == :selection ; end

  #---------------------------------------------------------------------------
  # Frame Update
  #---------------------------------------------------------------------------
  def update
    if cursor_movable?
      process_cursor_move
      process_mouse_handling if Input.method == :mouse
    end
  end

  def update_adaptive_cursor
    @adapt_dir[:up] = @cursor[0] > @adapt_dir[:actor_row] ? :left : :right
    @adapt_dir[:down] = @cursor[0] < @adapt_dir[:actor_row] ? :left : :right
  end
  #---------------------------------------------------------------------------
  # Cause the cursor to "bend" around the actor making an input.
  #---------------------------------------------------------------------------
  def setup_adaptive_cursor
    @adapt_dir[:actor_row] = BattleManager.actor.grid_row
    update_adaptive_cursor
  end
  #---------------------------------------------------------------------------
  # Set phase to influence grid state - :input, :selection, :idle
  #---------------------------------------------------------------------------
  def set_phase(phase)
    case phase
    when :input
      @phase = :input
      set_origin(*BattleManager.actor.grid_coordinates[0])
    when :selection
      @phase = :selection
      setup_adaptive_cursor
    when :idle
      @phase = :idle
    end
  end
  #---------------------------------------------------------------------------
  # Handle directional movement on the grid.
  #---------------------------------------------------------------------------
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
      @intersect = true
      Sound.play_grid_move
      cursor_deselect(get(*last))
      recalculate_area
      cursor_select(get(*@cursor))
      update_adaptive_cursor
    end
  end

  def process_mouse_handling
    return unless $mouse.enabled? && cursor_movable?
    # Add a delay to prevent too-fast scrolling
    @mouse_delay = @mouse_delay ? @mouse_delay + 1 : 0
    return if @mouse_delay % 3 > 0

    mx, my = *Mouse.position
    return if [mx, my] == @last_mouse_pos
    last = @cursor.dup
    @intersect = false

    @sel_movable.each do |tile|
      if tile.mouse_intersect(mx, my)
        @intersect = true
        set_cursor_tile(tile)
        unless @cursor.eql?(last)
          Sound.play_grid_move
          cursor_deselect(get(*last))
          recalculate_area
          cursor_select(get(*@cursor))
          update_adaptive_cursor
        end
        break
      end
    end
    cursor_deselect(get(*@cursor)) unless @intersect
    @last_mouse_pos = Mouse.position
  end

  #---------------------------------------------------------------------------
  # Determine whether a tile is being currently hovered.
  #---------------------------------------------------------------------------
  def intersect?
    @intersect
  end

  #---------------------------------------------------------------------------
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

  #---------------------------------------------------------------------------
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

  #---------------------------------------------------------------------------
  # Return an array of tiles given a 2D array of coordinates. [[y,x]]
  #---------------------------------------------------------------------------
  def tiles_from_coordinates(region = [])
    result = []
    region.each {|pair|
      next unless @grid[pair[0]] && get(*pair)
      result.push(get(*pair))
    }
    return result
  end
  #---------------------------------------------------------------------------
  # Tile selection and highlighting for UI
  #---------------------------------------------------------------------------
  def get(row, col) ; @grid[row][col] ; end
  def all_tiles     ; @tilelist       ; end
  #---------------------------------------------------------------------------
  # * Setters
  #---------------------------------------------------------------------------
  def set_origin(row, col)
    @cursor = [row, col]
    cursor_select(get(*@cursor))
  end

  def set_cursor_tile(tile)
    @cursor = tile.coordinates_rc
    cursor_select(tile)
  end

  def set_area_item(item) ; @area_item = item ; end
  #---------------------------------------------------------------------------
  # Remake the area of effect around the cursor.
  #---------------------------------------------------------------------------
  def recalculate_area
    return if @area_item.nil? || @sel_area.empty?
    unhighlight_for_area(@sel_area)
    @sel_area = Revoked::Grid::make_area_tiles(self, get(*@cursor), @area_item)
  end
  #---------------------------------------------------------------------------
  # Prepare the grid to allow the player to select a tile/battler.
  #---------------------------------------------------------------------------
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
  #---------------------------------------------------------------------------
  # Clear the grid selection UI.
  #---------------------------------------------------------------------------
  def finish_target_selection
    reset_tiles(all_tiles)
    @area_item = nil
    @sel_area.clear
    @sel_available.clear
    @sel_potential.clear
    @sel_movable = all_tiles
  end
  #---------------------------------------------------------------------------
  # * Sprite changes
  #---------------------------------------------------------------------------
  def cursor_select(tile) ; tile.select_tile end
  def cursor_deselect(tile)
    tile.deselect_tile
    tile.unlight_area
  end
  #---------------------------------------------------------------------------
  # Highlighting. Handles both array arguments 't' and a single HexTile 't'.
  #---------------------------------------------------------------------------
  def highlight_for_area(t)
    t.light_area if t.is_a?(HexTile) && !t.equal?(get(*@cursor))
    t.each {|h| h.light_area if !h.equal?(get(*@cursor))} if t.is_a?(Array)
  end
  def unhighlight_for_area(t)
    t.light_area if t.is_a?(HexTile) && !t.equal?(get(*@cursor))
    t.each {|h| h.unlight_area if !h.equal?(get(*@cursor))} if t.is_a?(Array)
  end
  #---------------------------------------------------------------------------
  # Opacity changes
  #---------------------------------------------------------------------------
  def make_available(tiles) ; tiles.each {|t| t.opacity_available_tile } end
  def make_potential(tiles) ; tiles.each {|t| t.opacity_potential_tile } end
  def make_dim(tiles)       ; tiles.each {|t| t.opacity_dim_tile } end
  #---------------------------------------------------------------------------
  # Revert the supplied array of tiles to their original appearance.
  #---------------------------------------------------------------------------
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

  def relocate_unit_tiles(unit, new_tiles)
    raise "wrong movement size" unless unit.grid_size == new_tiles.size
    remove_unit(unit)
    #msgbox_p(unit.grid_coordinates)
    new_tiles.each {|tile| tile.add_unit(unit) }

    tiles = new_tiles.collect {|tile| tile.coordinates_rc }
    #msgbox_p(tiles)
    unit.set_grid_location(tiles)
  end

  def relocate_unit_rc(unit, new_coordinates)
    raise "wrong movement size" unless unit.grid_size == new_coordinates.size

    orig = unit.grid_coordinates.dup
    (orig - new_coordinates).each {|rc| get(*rc).remove_unit(unit) }
    (new_coordinates - orig).each {|rc| get(*rc).add_unit(unit) }

    unit.set_grid_location(new_coordinates)
  end
  #----------------------------------------------------------------------------
  # Get the array of units currently within the cursor + area range.
  #----------------------------------------------------------------------------
  def get_selected_units
    units = []
    @sel_area.each {|tile| units.push(tile.unit_contents) }
    units.flatten!
    units.uniq!
    return units
  end
  #----------------------------------------------------------------------------
  # Get an array of the tiles in the player selectable region of the grid.
  #----------------------------------------------------------------------------
  def copy_available_area
    tiles_in_area = []
    @sel_available.each {|tile| tiles_in_area << tile}
    return tiles_in_area
  end
  #----------------------------------------------------------------------------
  # Get an array of tiles where the cursor + area currently covers.
  #----------------------------------------------------------------------------
  def copy_targeted_area
    tiles_in_area = []
    @sel_area.each {|tile| tiles_in_area << tile}
    return tiles_in_area
  end
end # HexGrid

#=============================================================================
# ■ HexTile
#=============================================================================
class HexTile
  #---------------------------------------------------------------------------
  # * Public Instance Variables
  #---------------------------------------------------------------------------
  attr_reader :unit_contents
  #---------------------------------------------------------------------------
  # * Object Initialization
  #---------------------------------------------------------------------------
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
  #---------------------------------------------------------------------------
  # Update all sprites
  #---------------------------------------------------------------------------
  def refresh
    @floor_sprite.update
    @select_sprite.update if @selected
  end
  #---------------------------------------------------------------------------
  # Free
  #---------------------------------------------------------------------------
  def dispose
    @unit_contents.clear
    @floor_sprite.dispose
    @select_sprite.dispose
  end
  #---------------------------------------------------------------------------
  # Override x=
  #---------------------------------------------------------------------------
  def x=(x_var)
    @x = x_var
    @floor_sprite.x = x_var
    @select_sprite.x = x_var
  end
  #---------------------------------------------------------------------------
  # Override y=
  #---------------------------------------------------------------------------
  def y=(y_var)
    @y = y_var
    @floor_sprite.y = y_var
    @select_sprite.y = x_var
  end
  #---------------------------------------------------------------------------
  # Get [x,y] hash keys for the grid
  #---------------------------------------------------------------------------
  def coordinates_xy ; return [@ind_x, @ind_y] end
  def coordinates_rc ; return [@ind_y, @ind_x] end
  #------------------------------\
  # Tile colouring and appearance \--------------------------------------------
  #---------------------------------------------------------------------------
  # Set colour to claimed scheme
  #---------------------------------------------------------------------------
  def ally_tile    ; @floor_sprite.color.set(64,160,224,192) end
  def enemy_tile   ; @floor_sprite.color.set(224,128,128,192) end
  def neutral_tile ; @floor_sprite.color.set(224,224,224,224) end
  #---------------------------------------------------------------------------
  # Highlight the unit receiving a command.
  #---------------------------------------------------------------------------
  def select_input_unit
    select_tile
  end
  #---------------------------------------------------------------------------
  # Highlight graphic.
  #---------------------------------------------------------------------------
  def select_tile
    @selected = true
    @select_sprite.bitmap = Cache.grid("htile_glow")
    @select_sprite.opacity = 200
    refresh
  end
  #---------------------------------------------------------------------------
  # Set tile to default / deselected apperance.
  #---------------------------------------------------------------------------
  def deselect_tile
    @selected = false
    @select_sprite.opacity = 0
    refresh
  end
  #---------------------------------------------------------------------------
  # Secondary tile from main tile appearance (i.e., area of effect radius).
  #---------------------------------------------------------------------------
  def light_area
    @selected = true
    @select_sprite.bitmap = Cache.grid("htile_glow_s")
    @select_sprite.opacity = 200
    refresh
  end
  #---------------------------------------------------------------------------
  # Remove secondary tile from main tile appearance
  #---------------------------------------------------------------------------
  def unlight_area
    @selected = false
    @select_sprite.opacity = 0
    refresh
  end

  #---------------------------------------------------------------------------
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

  #---------------------------------------------------------------------------
  # Return whether the tile has one or more units on it.
  #---------------------------------------------------------------------------
  def occupied? ; return !@unit_contents.nil? && !@unit_contents.empty? ; end

  #---------------------------------------------------------------------------
  # Return whether the given mouse coordinates intersect with this tile.
  #---------------------------------------------------------------------------
  def mouse_intersect(mouse_x, mouse_y)
    x_box = @floor_sprite.x + Revoked::Grid::TileBoxPadLeft
    box_start = Revoked::Grid::TileYBoxStart
    box_end = Revoked::Grid::TileYBoxEnd

    x_range = [x_box, x_box + Revoked::Grid::TileWidth]
    y_range = [@floor_sprite.y + box_start, @floor_sprite.y + box_end]

    box = [x_range, y_range]

    return false if mouse_x < box[0][0] # Too far left
    return false if mouse_x > box[0][1] # Too far right

    in_x = mouse_x.between?(box[0][0], box[0][1])
    in_y = mouse_y.between?(box[1][0], box[1][1])
    return true if in_x && in_y # Cursor in center box

    less_y = mouse_y < box[1][0]
    in_less_y = (less_y && (box[1][0] - mouse_y) < 15)
    return false if less_y && !in_less_y # Too far up

    greater_y = mouse_y > box[1][1]
    in_greater_y = (greater_y && (box[1][1] - mouse_y) > -15)
    return false if greater_y && !in_greater_y # Too far down

    right_side = mouse_x > ((box[0][0] + box[0][1]) / 2)
    trig_x = right_side ? (mouse_x - box[0][1]).abs : (mouse_x - box[0][0]).abs
    trig_y = (trig_x * 2) / 3 # tan(17/29) = 0.664 ~= 2/3

    if in_less_y
      return true if mouse_y > (box[1][0] - trig_y) # Cursor in top triangle
    elsif in_greater_y
      return true if mouse_y < (box[1][1] + trig_y) # Cursor in bottom triangle
    end
    return false
  end
end # HexTile

#=============================================================================
# ■ Grid Arrow
#=============================================================================
class GridArrow
  #---------------------------------------------------------------------------
  # * Object Initialization
  #---------------------------------------------------------------------------
  def initialize(viewport)
    @viewport = viewport
    @arrow = Sprite.new(@viewport)
    @arrow.bitmap = Cache.grid("arrow_1")
    set_opacity(0)
    @index = 1
  end

  #---------------------------------------------------------------------------
  # Update the row,col coordinates of the arrow.
  #---------------------------------------------------------------------------
  def update_position(row, col)
    pos = Revoked::Grid.position(row, col)
    self.x = pos[:x]
    self.y = pos[:y]
  end
  #---------------------------------------------------------------------------
  # Update the arrow sprite frame. (Spinny animation)
  #---------------------------------------------------------------------------
  def update_index
    @index += 1
    @index = 1 if @index > 30
    self.bitmap = Cache.grid("arrow_#{@index/6}") if @index % 6 == 0
  end
  #---------------------------------------------------------------------------
  # Set the opacity of the arrow.
  #---------------------------------------------------------------------------
  def set_opacity(opacity)
    @arrow.opacity = opacity
    @visible = opacity == 0 ? false : true
  end
end # GridArrow

#==============================================================================
#
# ▼ End of File
#
#==============================================================================
