#==============================================================================
# Grid Shift Phase Turn Battle System - Target Handling
#------------------------------------------------------------------------------
#  This script handles target selection, tracking, and windows.
#==============================================================================


#=============================================================================
# ■ Game_Action
#=============================================================================
class Game_Action


  attr_reader :target_grid
  def set_target_region(region)
    @target_grid = region.is_a?(Array) ? region : []
  end

  attr_reader :targets_initial
  def set_initial_targets(units)
    @targets_initial = units
  end

end # Game_Action

#=============================================================================
# ■ Scene_Battle
#=============================================================================
class Scene_Battle < Scene_Base

  alias rvkd_phaseturn_scb_create_all_windows create_all_windows
  def create_all_windows
    rvkd_phaseturn_scb_create_all_windows
    create_grid_target_window
  end

  def create_grid_target_window
    @target_window = Window_GridTarget.new(@hex_grid)
    @target_window.set_handler(:ok,     method(:on_target_ok))
    @target_window.set_handler(:cancel, method(:on_target_cancel))
  end

  # override functions that begin target selection ----------------------------
  def command_attack
    usable_item = $data_skills[BattleManager.actor.attack_skill_id]
    BattleManager.actor.input.set_skill(usable_item.id)
    select_target_selection(BattleManager.actor, usable_item)
  end

  def command_guard
    usable_item = $data_skills[BattleManager.actor.guard_skill_id]
    BattleManager.actor.input.set_skill(usable_item.id)
    select_target_selection(BattleManager.actor, usable_item)
  end

  def on_skill_ok
    usable_item = @skill_window.item
    BattleManager.actor.input.set_skill(usable_item.id)
    select_target_selection(BattleManager.actor, usable_item)
  end

  def on_item_ok
    usable_item = @item_window.item
    BattleManager.actor.input.set_item(usable_item.id)
    select_target_selection(BattleManager.actor, usable_item)
  end

  # Set up the target window and grid for selection
  def select_target_selection(battler, usable_item)
    @target_window.refresh
    @target_window.show.activate
    @target_window.setup_range(battler, usable_item)
    @hex_grid.set_phase(:selection)
  end

  def on_target_ok
    # primitive set: need to calculate area from ability with anchor point
    BattleManager.actor.input.set_target_region(@hex_grid.copy_selected_area)
    BattleManager.actor.input.set_initial_targets(@hex_grid.get_selected_units)
    create_timeslot_action(BattleManager.actor, BattleManager.actor.input)
    @target_window.cancel_target_selection
    @hex_grid.set_phase(:idle)
    next_command
  end

  def on_target_cancel
    @target_window.deactivate
    @target_window.hide
    @target_window.cancel_target_selection
    case @actor_command_window.current_symbol
    when :attack, :guard
      @actor_command_window.activate
    when :skill
      @skill_window.activate
    when :item
      @item_window.activate
    end
    @hex_grid.set_phase(:input)
  end

end

#=============================================================================
# ■ Window_ActorCommand
#=============================================================================
class Window_ActorCommand < Window_Command
  def cancel_enabled? ; false ; end
end

#=============================================================================
# ■ Window_GridTarget
#=============================================================================
class Window_GridTarget < Window_Command

  def initialize(battle_grid)
    super(0, 0)
    @battle_grid = battle_grid
    refresh
    self.openness = 0
    self.active = false
  end

  def update
    super
    if self.active
      @battle_grid.update
    end
  end

  def setup_range(battler, item)
    origin = [battler.grid_row, battler.grid_col]
    interact = Revoked::Grid.make_interact_tiles(@battle_grid, origin, item)
    available = interact[:available]
    potential = interact[:potential]
    cursor_t = Revoked::Grid.auto_cursor(@battle_grid, origin, available, item)
    area = Revoked::Grid.make_area_tiles(@battle_grid, cursor_t, item)

    @battle_grid.set_area_item(item)
    @battle_grid.setup_target_selection(cursor_t, available, potential, area)
  end

  def cancel_target_selection
    @battle_grid.cancel_target_selection
  end

  def process_handling
    return unless active
    return process_ok     if ok_enabled?     && Input.trigger?(:C)
    return process_cancel if cancel_enabled? && Input.trigger?(:B)
  end

  # override
  def process_ok
    targets = @battle_grid.get_selected_units
    if (!targets.nil? && !targets.empty?)
      Sound.play_ok
      Input.update
      deactivate
      call_ok_handler
    else
      Sound.play_buzzer
    end
  end

  # override
  def process_cancel
    Sound.play_cancel
    Input.update
    deactivate
    call_cancel_handler
  end

end # Window_GridTarget
