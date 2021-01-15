#==============================================================================
# Grid Shift Phase Turn Battle System - Troops, Party
#------------------------------------------------------------------------------
#  This script defines and implements troop and party setup and logic.
#==============================================================================
# ■ Game_Troop
#==============================================================================
class Game_Troop
  #---------------------------------------------------------------------------
  # Add the given troop members to tile objects on the grid.
  #---------------------------------------------------------------------------
  def setup_grid_positions(hex_grid)
    members.each do |member|
      coordinates = Grid.troop_battler_coordinates(member)
      Grid.reset_troop_screen_xy(member, coordinates)

      containing_tiles = hex_grid.tiles_from_coordinates(coordinates)
      containing_tiles.each {|tile| tile.add_unit(member)}
    end
  end
end # Game_Troop

#==============================================================================
# ■ Game_Party
#==============================================================================
class Game_Party
  #---------------------------------------------------------------------------
  # * Public Instance Variables
  #---------------------------------------------------------------------------
  attr_reader :grid_positions
  #---------------------------------------------------------------------------
  # * Object Initialization
  #---------------------------------------------------------------------------
  alias rvkd_hexgrid_gpa_initialize initialize
  def initialize
    rvkd_hexgrid_gpa_initialize
    @grid_positions = Grid::Config::DefaultPositions
  end
  #---------------------------------------------------------------------------
  # Add the given party members to tile objects on the grid.
  #---------------------------------------------------------------------------
  def setup_grid_positions(hex_grid)
    members.each do |member|
      coordinates = member.grid_coordinates
      coordinates.each {|pair| hex_grid.get(*pair).add_unit(member) }
    end
  end
end # Game_Party

#==============================================================================
#
# ▼ End of File
#
#==============================================================================
