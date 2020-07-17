#==============================================================================
# Grid Shift Phase Turn Battle System - Spriteset
#------------------------------------------------------------------------------
#  This script handles Spriteset_Battle adjustments.
#==============================================================================
# ■ Spriteset_Battle
#==============================================================================
class Spriteset_Battle
  #===========================================================================
  # Event Bar
  #---------------------------------------------------------------------------
  # Create the battle event display with the UI viewport.
  #---------------------------------------------------------------------------
  def create_event_display
    @event_display = PhaseTurn.create_event_display(@viewport1)
    return @event_display
  end
  #---------------------------------------------------------------------------
  # * Free
  #---------------------------------------------------------------------------
  alias rvkd_phaseturn_bar_spb_dispose dispose
  def dispose
    rvkd_phaseturn_bar_spb_dispose
    dispose_turn_display
  end
  def dispose_turn_display ; @event_display.dispose_events ; end

  #============================================================================
  # Hex Grid
  #---------------------------------------------------------------------------
  # Create the HexGrid object.
  #---------------------------------------------------------------------------
  def create_grid
    @battle_grid = HexGrid.new(@viewport0)
    return @battle_grid
  end
  #---------------------------------------------------------------------------
  # Make a new viewport for the HexGrid.
  #---------------------------------------------------------------------------
  alias rvkd_hexgrid_spb_create_viewports create_viewports
  def create_viewports
    rvkd_hexgrid_spb_create_viewports
    @viewport0 = Viewport.new
    @viewport0.z = 0
    @viewport1.z = 25
  end
  #---------------------------------------------------------------------------
  # Override - create_battleback1 to place it below the grid.
  #---------------------------------------------------------------------------
  def create_battleback1
    @back1_sprite = Sprite.new(@viewport0)
    @back1_sprite.bitmap = battleback1_bitmap
    @back1_sprite.z = 0
  end
  #---------------------------------------------------------------------------
  # Update Viewport
  #---------------------------------------------------------------------------
  alias rvkd_hexgrid_spb_update_viewports update_viewports
  def update_viewports
    rvkd_hexgrid_spb_update_viewports
    @viewport0.update
  end
  #---------------------------------------------------------------------------
  # * Free
  #---------------------------------------------------------------------------
  alias rvkd_hexgrid_spb_dispose dispose
  def dispose
    rvkd_hexgrid_spb_dispose
    dispose_grid
  end
  def dispose_grid
    @battle_grid.dispose_grid
  end
end # Spriteset_Battle
