#==============================================================================
# Grid Shift Phase Turn Battle System - Game_Action
#------------------------------------------------------------------------------
#  This script defines and implements RPG Game_Action and Game_ActionResult
#  behaviour and logic.
#==============================================================================
# ■ Game_Action
#==============================================================================
class Game_Action

  #---------------------------------------------------------------------------
  # * Public Instance Variables
  #---------------------------------------------------------------------------
  attr_reader :available_grid
  attr_reader :targeted_grid
  attr_reader :targets_initial
  #---------------------------------------------------------------------------
  # The tiles the item can be targeted at.
  #---------------------------------------------------------------------------
  def set_available_region(region)
    @available_grid = region.is_a?(Array) ? region : []
  end
  #---------------------------------------------------------------------------
  # The tiles the item is aimed at.
  #---------------------------------------------------------------------------
  def set_targeted_region(region)
    @targeted_grid = region.is_a?(Array) ? region : []
  end
  #---------------------------------------------------------------------------
  # The units originally intended to be hit by the item.
  #---------------------------------------------------------------------------
  def set_initial_targets(units)
    @targets_initial = units
  end
  #---------------------------------------------------------------------------
  # Make the targets array for the action.
  # * Calls the grid version in battle; call original outside of battle.
  #---------------------------------------------------------------------------
  alias rvkd_hexgrid_gaa_make_targets make_targets
  def make_targets
    return rvkd_hexgrid_gaa_make_targets unless subject.actor? # TODO: Enemy
    return rvkd_hexgrid_gaa_make_targets if SceneManager.scene_is?(Scene_Menu)

    if item.target_homing
      targets = targets_initial
    else
      # Check for original target(s) in range
      targets = PhaseTurn.units_in_area(@targeted_grid)
      # Re-target if targets are empty and item is retargetable
      if targets.empty? && item.retargetable
        available_targets = PhaseTurn.units_in_area(@available_grid)
        targets = [available_targets.sample] unless available_targets.empty?
      end
    end
    return targets
  end
  #---------------------------------------------------------------------------
  # Calculate the time it takes before the action is executed.
  # Typically 0; affects TimeSlotAction enqueue order in the turn schedule.
  #---------------------------------------------------------------------------
  def prep_time
    time = item.prep_time
    fixed = item.prep_fixed
    if fixed
      return time # return the flat time if it cannot be modified
    else
      return time # return the time adjusted with speed (TODO)
    end
  end
  #---------------------------------------------------------------------------
  # Calculate the time before the unit's next turn.
  #---------------------------------------------------------------------------
  def reset_time
    time = item.reset_time
    fixed = item.reset_fixed
    if fixed
      return time # return the flat time if it cannot be modified
    else
      return time # return the time adjusted with speed (TODO)
    end
  end
end # Game_Action

#=============================================================================
# ■ Game_ActionResult
#=============================================================================
class Game_ActionResult
  #---------------------------------------------------------------------------
  # Calls for an event display bar refresh when a 'reveal' state is changed.
  #---------------------------------------------------------------------------
  def need_refresh_event_bar?
    arr = @added_states + @removed_states
    return arr.any? {|s| $data_states[s].reveal_actions?}
  end
end # Game_ActionResult

#==============================================================================
#
# ▼ End of File
#
#==============================================================================
