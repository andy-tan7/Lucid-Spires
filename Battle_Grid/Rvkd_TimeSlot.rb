#==============================================================================
# Grid Shift Phase Turn Battle System - TimeSlots
#------------------------------------------------------------------------------
#  This script defines the different types of events that can exist on the
#  Phase Turn event bar in battle.
#==============================================================================
# ■ Rvkd_TimeSlotEvent
#==============================================================================
class Rvkd_TimeSlotEvent
  attr_reader :time
  attr_reader :battler
  def initialize(time, phase_shift = false)
    @time = time
    @phase_shift = phase_shift
  end
  def phase ; timeslot / PhaseTurn::Calc::PHASE_DURATION ; end
  #---------------------------------------------------------------------------
  # * Virtual methods
  #---------------------------------------------------------------------------
  def subject      ; nil    ; end   # Unit / source associated with the event.
  def type         ; :event ; end   # Event, Turn, or Action
  def revealed?    ; false  ; end   # Whether the player can see the item name.
  def phase_shift? ; @phase_shift ; end # Whether this is a phase shift event.
  def icon ; @phase_shift ? 280 : nil ; end   # Effect icon or action icon
end # Rvkd_TimeSlotEvent

#=============================================================================
# ■ Rvkd_TimeSlotTurn
#=============================================================================
class Rvkd_TimeSlotTurn < Rvkd_TimeSlotEvent
  def initialize(time, battler)
    super(time)
    @battler = battler    # Game_Battler
  end
  #---------------------------------------------------------------------------
  # Return the battler type.
  #---------------------------------------------------------------------------
  def unit_type
    return Game_Actor if battler.is_a?(Game_Actor)
    return Game_Enemy if battler.is_a?(Game_Enemy)
    return nil
  end
  #---------------------------------------------------------------------------
  # * Override methods
  #---------------------------------------------------------------------------
  def subject      ; @battler ; end
  def type         ; :turn    ; end
  def icon         ; nil      ; end   # Effect icon or action icon
  def phase_shift? ; false    ; end
end # Rvkd_TimeSlotTurn

#=============================================================================
# ■ Rvkd_TimeSlotAction
#=============================================================================
class Rvkd_TimeSlotAction < Rvkd_TimeSlotTurn
  attr_reader :action
  def initialize(time, battler, action)
    super(time, battler)
    @revealed = battler.actions_revealed?
    set_action(action) # Set the event Game_Action
  end
  #---------------------------------------------------------------------------
  # * Setters
  #---------------------------------------------------------------------------
  def set_action(action) ; @action = action ; end
  def reveal ; @revealed = true  ; end
  def hide   ; @revealed = false ; end
  #---------------------------------------------------------------------------
  # * Override methods
  #---------------------------------------------------------------------------
  def type ; :action ; end
  def icon ; @action.item ? @action.item.icon_index : nil ; end
  def revealed? ; @revealed ; end
end # Rvkd_TimeSlotAction

#==============================================================================
#
# ▼ End of File
#
#==============================================================================
