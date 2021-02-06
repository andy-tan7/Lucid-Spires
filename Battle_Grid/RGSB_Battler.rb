#==============================================================================
# Grid Shift Phase Turn Battle System - Battlers, Actors, Enemies
#------------------------------------------------------------------------------
#  This script defines and implements battler-related fields and functions.
#==============================================================================
# ■ Game_BattlerBase
#==============================================================================
class Game_BattlerBase

  alias rvkd_phaseturn_gbb_clear_states clear_states
  def clear_states
    rvkd_phaseturn_gbb_clear_states
    @state_phases = {}
  end

  alias rvkd_phaseturn_gbb_erase_state erase_state
  def erase_state(state_id)
    rvkd_phaseturn_gbb_erase_state(state_id)
    @state_phases.delete(state_id)
  end

end
#==============================================================================
# ■ Game_Battler
#==============================================================================
class Game_Battler < Game_BattlerBase

  #============================================================================
  # HexGrid
  #----------------------------------------------------------------------------
  def set_grid_location(locations)
    @grid_coordinates = locations
  end

  def grid_size ; 1 end
  def grid_row ; @grid_coordinates[0][0] end
  def grid_col ; @grid_coordinates[0][1] end
  def grid_coordinates ; @grid_coordinates end
  #============================================================================
  # PhaseTurn
  #----------------------------------------------------------------------------
  # * Public Instance Variables
  #---------------------------------------------------------------------------
  attr_reader :current_reset_time
  #---------------------------------------------------------------------------
  # * Object Initialization
  #---------------------------------------------------------------------------
  alias rvkd_phaseturn_gbt_initialize initialize
  def initialize
    @current_reset_time = 0
    rvkd_phaseturn_gbt_initialize
  end
  #---------------------------------------------------------------------------
  # * Setters
  #---------------------------------------------------------------------------
  def set_reset_time(time)
    @current_reset_time = time
  end
  def set_actions(actions)
    @actions = actions
  end
  #---------------------------------------------------------------------------
  # Check whether this unit's turn / event actions are visible to the player.
  #---------------------------------------------------------------------------
  def actions_revealed?
    return true if actor?
    return states.any? {|state| state.reveal_actions? == true }
  end
  #---------------------------------------------------------------------------
  # Add a turn event bar update check for when a Reveal state is changed.
  #---------------------------------------------------------------------------
  alias rvkd_phaseturn_gbt_item_apply item_apply
  def item_apply(user, item)
    rvkd_phaseturn_gbt_item_apply(user, item)
    if SceneManager.scene_is?(Scene_Battle) && @result.need_refresh_event_bar?
      TurnManager.refresh_revealed_events
    end
  end
  #============================================================================
  # EventBar
  #----------------------------------------------------------------------------
  def battle_event_bar_face
    return "_" + name
  end
  #----------------------------------------------------------------------------
  # State timing
  #----------------------------------------------------------------------------
  # Call on phase shift to decrement phase expiration states.
  def update_state_phases
    states.each {|s| @state_phases[s.id] -= 1 if @state_phases[s.id] > 0 }
  end

  alias rvkd_phaseturn_gbt_remove_states_auto remove_states_auto
  def remove_states_auto(timing)
    rvkd_phaseturn_gbt_remove_states_auto(timing)
    states.each {|s| remove_state(s.id) if @state_phases[s.id] == 0 }
  end

  alias rvkd_phaseturn_gbt_reset_state_counts reset_state_counts
  def reset_state_counts(state_id)
    rvkd_phaseturn_gbt_reset_state_counts(state_id)
    @state_phases[state_id] = $data_states[state_id].min_phases
  end

end

#==============================================================================
# ■ Game_Actor
#==============================================================================
class Game_Actor < Game_Battler
  #============================================================================
  # HexGrid
  #----------------------------------------------------------------------------
  def set_grid_coordinates(row, col)
    @grid_coordinates = [[row, col]]
  end

  def grid_coordinates ; @grid_coordinates ; end

end # Game_Actor

#==============================================================================
# ■ Game_Enemy
#==============================================================================
class Game_Enemy < Game_Battler
  #===========================================================================
  # HexGrid
  #---------------------------------------------------------------------------
  # Check the number of tiles the battler takes up.
  #---------------------------------------------------------------------------
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
  #---------------------------------------------------------------------------
  # Remove an enemy from the grid when it dies.
  # TODO: Special case for revivable enemies.
  #---------------------------------------------------------------------------
  alias rvkd_hexgrid_gen_die die
  def die
    rvkd_hexgrid_gen_die
    TurnManager.remove_grid_unit(self)
  end

  #===========================================================================
  # PhaseTurn
  #---------------------------------------------------------------------------
  # Replacement to Game_Enemy.make_actions
  # Create an array of actions for the battler to execute.
  #---------------------------------------------------------------------------
  def prepare_actions
    clear_actions
    return unless movable?
    act_arr = Array.new(make_action_times) { Game_Action.new(self) }

    return if act_arr.empty?
    action_list = enemy.actions.select {|a| action_valid?(a) }
    return if action_list.empty?
    rating_max = action_list.collect {|a| a.rating }.max
    rating_zero = rating_max - 3
    action_list.reject! {|a| a.rating <= rating_zero }
    act_arr.each do |action|
      action.set_enemy_action(select_enemy_action(action_list, rating_zero))
    end
    return act_arr
  end

  #===========================================================================
  # EventBar
  #---------------------------------------------------------------------------
  def battle_event_bar_face
    return "_" + $1.to_s if enemy.note =~ /<event_face[\s_]*:\s*(\w+)>/i
    return ""
  end
end # Game_Enemy

#==============================================================================
#
# ▼ End of File
#
#==============================================================================
