#==============================================================================
# Grid Shift Phase Turn Battle System - Target Handling
#------------------------------------------------------------------------------
#  This script handles target selection, tracking, and windows.
#==============================================================================
# ■ Scene_Battle
#=============================================================================
class Scene_Battle < Scene_Base
  #---------------------------------------------------------------------------
  # * Create All Windows
  #---------------------------------------------------------------------------
  alias rvkd_phaseturn_scb_create_all_windows create_all_windows
  def create_all_windows
    rvkd_phaseturn_scb_create_all_windows
    create_grid_target_window
  end
  #---------------------------------------------------------------------------
  # * Create Target Window
  #---------------------------------------------------------------------------
  def create_grid_target_window
    @target_window = Window_GridTarget.new(@hex_grid)
    @target_window.set_handler(:ok,     method(:on_target_ok))
    @target_window.set_handler(:cancel, method(:on_target_cancel))
  end
  #---------------------------------------------------------------------------
  # * Override - Methods that begin target selection
  #---------------------------------------------------------------------------
  # Confirming [Attack]
  def command_attack
    usable_item = $data_skills[BattleManager.actor.attack_skill_id]
    BattleManager.actor.input.set_skill(usable_item.id)
    select_target_selection(BattleManager.actor, usable_item)
  end

  # Confirming [Guard]
  def command_guard
    usable_item = $data_skills[BattleManager.actor.guard_skill_id]
    BattleManager.actor.input.set_skill(usable_item.id)
    select_target_selection(BattleManager.actor, usable_item)
  end

  # Confirming a selection on the [Skill] menu
  def on_skill_ok
    usable_item = @skill_window.item
    @skill_window.hide
    BattleManager.actor.input.set_skill(usable_item.id)
    select_target_selection(BattleManager.actor, usable_item)
  end

  # Confirming a selection on the [Item]/inventory menu
  def on_item_ok
    usable_item = @item_window.item
    @item_window.hide
    BattleManager.actor.input.set_item(usable_item.id)
    select_target_selection(BattleManager.actor, usable_item)
  end
  #---------------------------------------------------------------------------
  # Set up the target window and grid for selection
  #---------------------------------------------------------------------------
  def select_target_selection(battler, usable_item)
    @target_window.refresh
    @target_window.show.activate
    @target_window.setup_range(battler, usable_item)
    @hex_grid.set_phase(:selection)
  end
  #---------------------------------------------------------------------------
  # Final confirmation of a selected target/pos on the grid for a skill/item.
  #---------------------------------------------------------------------------
  def on_target_ok
    # primitive set: need to calculate area from ability with anchor point
    action = BattleManager.actor.input
    action.set_available_region(@hex_grid.copy_available_area)
    action.set_targeted_region(@hex_grid.copy_targeted_area)
    action.set_initial_targets(@hex_grid.get_selected_units)
    queue_actor_next_turn(BattleManager.actor, action)
    @target_window.finish_target_selection(false)
    @hex_grid.set_phase(:idle)
    next_command
  end
  #---------------------------------------------------------------------------
  # Canceling grid/target selection
  #---------------------------------------------------------------------------
  def on_target_cancel
    @target_window.deactivate
    @target_window.hide
    @target_window.finish_target_selection(true)
    case @actor_command_window.current_symbol
    when :attack, :guard
      @actor_command_window.activate
    when :skill
      @skill_window.show.activate
    when :item
      @item_window.show.activate
    end
    @hex_grid.set_phase(:input)
  end
end # Scene_Battle

#=============================================================================
# ■ Window_ActorCommand
#=============================================================================
class Window_ActorCommand < Window_Command
  #---------------------------------------------------------------------------
  # Bypass the cancel handler; never allow canceling the main battle window.
  #---------------------------------------------------------------------------
  def cancel_enabled? ; false ; end
end # Window_ActorCommand

#=============================================================================
# ■ Window_GridTarget
#=============================================================================
class Window_GridTarget < Window_Command
  #---------------------------------------------------------------------------
  # * Object Initialization
  #---------------------------------------------------------------------------
  def initialize(hex_grid)
    super(0, 0)
    @hex_grid = hex_grid
    @current_item = nil
    refresh
    self.openness = 0
    self.active = false
  end
  #---------------------------------------------------------------------------
  # * Frame Update
  #---------------------------------------------------------------------------
  def update
    super
    if self.active
      @hex_grid.update
    end
  end
  #---------------------------------------------------------------------------
  # Open up grid targeting for the player to select their item destination.
  #---------------------------------------------------------------------------
  def setup_range(battler, item)
    @current_item = item

    origin = [battler.grid_row, battler.grid_col]
    interact = Revoked::Grid.make_interact_tiles(@hex_grid, origin, item)
    available = interact[:available]
    potential = interact[:potential]
    cursor_t = Revoked::Grid.auto_cursor(@hex_grid, origin, available, item)
    area = Revoked::Grid.make_area_tiles(@hex_grid, cursor_t, item)

    @hex_grid.set_area_item(item)
    @hex_grid.setup_target_selection(cursor_t, available, potential, area)

    dummy = Game_Action.new(battler)
    item.is_a?(RPG::Skill) ? dummy.set_skill(item.id) : dummy.set_item(item.id)
    temp = Revoked::Phase.create_temp_events(battler, dummy)
    PhaseTurn.indicate_player_selected_event(temp[0])
    PhaseTurn.indicate_player_selected_next_turn(temp[1])
  end
  #---------------------------------------------------------------------------
  # End grid targeting (confirm or cancel)
  #---------------------------------------------------------------------------
  def finish_target_selection(cancel)
    @hex_grid.finish_target_selection
    @current_item = nil
    PhaseTurn.cancel_indicated_events if cancel
  end
  #---------------------------------------------------------------------------
  # Handling Processing for OK and Cancel Etc.
  #---------------------------------------------------------------------------
  def process_handling
    return unless active
    return process_ok     if ok_enabled?     && Input.trigger?(:C)
    return process_cancel if cancel_enabled? && Input.trigger?(:B)
  end
  #---------------------------------------------------------------------------
  # Processing When OK Button Is Pressed
  #---------------------------------------------------------------------------
  def process_ok
    targets = @hex_grid.get_selected_units
    area = @hex_grid.copy_targeted_area
    intersect = @hex_grid.intersect?
    # Determine whether the ability can be used on the target.
    if Revoked::Grid.target_valid?(@current_item, targets, area) && intersect
      Sound.play_grid_confirm
      Input.update
      deactivate
      call_ok_handler
    else
      Sound.play_buzzer
    end
  end
  #---------------------------------------------------------------------------
  # Processing When Cancel Button Is Pressed
  #---------------------------------------------------------------------------
  def process_cancel
    Sound.play_cancel
    Input.update
    deactivate
    call_cancel_handler
  end
end # Window_GridTarget

#==============================================================================
#
# ▼ End of File
#
#==============================================================================
