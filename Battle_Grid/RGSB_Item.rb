#==============================================================================
# Grid Shift Phase Turn Battle System - RPG Items
#------------------------------------------------------------------------------
#  This script handles any adjustments and additions to the RPG::BaseItem tree
#  of classes.
#==============================================================================
# ■ RPG::UsableItem
#==============================================================================
class RPG::UsableItem < RPG::BaseItem

  #===========================================================================
  # ■ PhaseTurn Scheduling
  #---------------------------------------------------------------------------
  # Get the time the user waits before this item is executed.
  #---------------------------------------------------------------------------
  def prep_time
    return $1.to_i if self.note =~ /<prep[\s_]*:\s*(\d+)>/i
    return 0
  end
  #---------------------------------------------------------------------------
  # Get the delay until the user's next turn after using this item.
  #---------------------------------------------------------------------------
  def reset_time
    return $1.to_i if self.note =~ /<reset[\s_]*:\s*(\d+)>/i
    return Revoked::Phase::DEFAULT_RESET_TIME
  end
  #---------------------------------------------------------------------------
  # A fixed preparation time means it cannot be reduced with speed stats.
  #---------------------------------------------------------------------------
  def prep_fixed
    return true if self.note =~ /<fixed[\s_]*prep>/i
    return false
  end
  #---------------------------------------------------------------------------
  # If the delay after an action cannot be reduced with speed stats.
  #---------------------------------------------------------------------------
  def reset_fixed
    return true if self.note =~ /<fixed[\s_]*reset>/i
    return false
  end

  #===========================================================================
  # ■ Hex Grid Properties
  #---------------------------------------------------------------------------
  # Whether the skill will not retarget upon execution
  #---------------------------------------------------------------------------
  def target_homing
    return @target_homing unless @target_homing.nil?
    return false if @target_homing == false
    @target_homing = grid_selectable_tags.include?(:homing)
    return @target_homing
  end
  #---------------------------------------------------------------------------
  # Whether the skill will choose a new target if original ones are dead.
  #---------------------------------------------------------------------------
  def retargetable
    return @retargetable unless @retargetable.nil?
    return true if @retargetable == true
    @retargetable = !grid_selectable_tags.include?(:no_retarget)
    return @retargetable
  end
  #---------------------------------------------------------------------------
  # The hexagonal distance the item can reach.
  #---------------------------------------------------------------------------
  def ability_range
    return $1.to_i if self.note =~ /<grid[\s_]*range:[\s]*(\d+)>/i
    return 1
  end
  #---------------------------------------------------------------------------
  # Tags determining the spaces that can be selected by the user.
  #---------------------------------------------------------------------------
  def grid_selectable_tags
    if self.note =~ /<grid[\s\_]*select:[\s]*(.+)>/i
      return $1.split(%r{,\s*}).collect{|s| s.to_sym}
    end
    return [:radius]
  end
  #---------------------------------------------------------------------------
  # Tags determining the splash area expanding from the selected destination.
  #---------------------------------------------------------------------------
  def grid_area_tags
    if self.note =~ /<grid[\s\_]*area:[\s]*(.+)>/i
      return $1.split(%r{,\s*}).collect{|s| s.to_sym}
    end
    return []
  end
  #---------------------------------------------------------------------------
  # Tags defining any mandatory target selection requirements.
  #---------------------------------------------------------------------------
  def grid_force_target_tags
    if self.note =~ /<force[\s\_]*target:[\s]*(.+)>/i
      return $1.split(%r{,\s*}).collect{|s| s.to_sym}
    end
    return [:any]
  end
  #---------------------------------------------------------------------------
  # Return a tag based on the RPG Maker database scope value.
  #---------------------------------------------------------------------------
  def grid_target_type
    case @scope
    when 0                ; return :none
    when 1, 2, 3, 4, 5, 6 ; return :enemy
    when 7, 8             ; return :ally
    when 9, 10            ; return :ally_dead
    when 11               ; return :self
    end
  end
end # RPG::UsableItem

#=============================================================================
# ■ RPG::State
#=============================================================================
class RPG::State < RPG::BaseItem
  #---------------------------------------------------------------------------
  # Whether bearer's actions are named/telegraphed in the event order display.
  #---------------------------------------------------------------------------
  def reveal_actions?
    return @reveal_actions if @reveal_actions
    @reveal_actions = (self.note =~ /<reveal[\s_]*actions>/i) != nil
    return @reveal_actions
  end
end # RPG::State

#==============================================================================
#
# ▼ End of File
#
#==============================================================================
