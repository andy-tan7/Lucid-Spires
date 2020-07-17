#==============================================================================
# Grid Shift Phase Turn Battle System - Config
#------------------------------------------------------------------------------
#  This script handles Hex Grid Shift Battle constants and imports.
#==============================================================================
# ■ Revoked::Grid
#==============================================================================
module Revoked
  module Grid

    RadiusY = 1
    RadiusX = 4
    MaxHeight = 1 + 2 * RadiusY
    MaxWidth  = 1 + 2 * RadiusX

    TileHeight = 50
    TileWidth  = 58

    TileXOffset = -3
    TileYOffset = -10

    UnitXOffset = 32
    UnitYOffset = 48

    DefaultPositions = {
      1 => [0,1], # Clement
      2 => [1,2], # Amaina
      3 => [1,1], # Vermund
      4 => [-1,3] # Rinore
    }

  end
end

#==============================================================================
# ■ Cache
#==============================================================================
module Cache
  #---------------------------------------------------------------------------
  # * Get grid graphics
  #---------------------------------------------------------------------------
  def self.grid(filename)
    load_bitmap("Graphics/Grid/", filename)
  end
  def self.grid_turn(filename)
    load_bitmap("Graphics/Grid/Turn/", filename)
  end
end # module Cache

#=============================================================================
# ■ Sound
#=============================================================================
module Sound
  #---------------------------------------------------------------------------
  # * Custom grid sound effects
  #---------------------------------------------------------------------------
  def self.play_grid_error
    RPG::SE.new("FEA - Error1", 60, 95).play
  end
  def self.play_grid_move
    RPG::SE.new("FEA - Pop2", 80, 90).play
  end
  def self.play_grid_event_add
    RPG::SE.new("TBS_BATTLE_LIST", 80, 85).play
  end
  def self.play_grid_confirm
    RPG::SE.new("TBS_BATTLE_LIST", 90, 85).play
  end
end # module Cache

#==============================================================================
#
# ▼ End of File
#
#==============================================================================
