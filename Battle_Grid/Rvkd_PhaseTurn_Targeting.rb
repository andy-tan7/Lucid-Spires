#==============================================================================
# Grid Shift Phase Turn Battle System - Target Handling
#------------------------------------------------------------------------------
#  This script handles target selection, tracking, and windows.
#==============================================================================

#=============================================================================
# ■ Game_Action
#=============================================================================
class Game_Action

  attr_reader :available_grid
  attr_reader :targeted_grid
  attr_reader :targets_initial

  # The tiles the item can be targeted at.
  def set_available_region(region)
    @available_grid = region.is_a?(Array) ? region : []
  end

  # The tiles the item is aimed at.
  def set_targeted_region(region)
    @targeted_grid = region.is_a?(Array) ? region : []
  end

  # The units originally intended to be hit by the item.
  def set_initial_targets(units)
    @targets_initial = units
  end

  # Call the grid version in battle; call original outside of battle.
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

end # Game_Action

#=============================================================================
# ■ RPG::UsableItem
#=============================================================================
class RPG::UsableItem < RPG::BaseItem

  # Whether the skill will not retarget upon execution
  def target_homing
    return @target_homing unless @target_homing.nil?
    return false if @target_homing == false
    @target_homing = grid_selectable_tags.include?(:homing)
    return @target_homing
  end

  # Whether the skill will choose a new target if original ones are dead.
  def retargetable
    return @retargetable unless @retargetable.nil?
    return true if @retargetable == true
    @retargetable = !grid_selectable_tags.include?(:no_retarget)
    return @retargetable
  end

  def ability_range
    return $1.to_i if self.note =~ /<grid[\s_]*range:[\s]*(\d+)>/i
    return 1
  end

  def grid_selectable_tags
    if self.note =~ /<grid[\s\_]*select:[\s]*(.+)>/i
      return $1.split(%r{,\s*}).collect{|s| s.to_sym}
    end
    return [:radius]
  end

  def grid_area_tags
    if self.note =~ /<grid[\s\_]*area:[\s]*(.+)>/i
      return $1.split(%r{,\s*}).collect{|s| s.to_sym}
    end
    return []
  end

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
    action = BattleManager.actor.input
    action.set_available_region(@hex_grid.copy_available_area)
    action.set_targeted_region(@hex_grid.copy_targeted_area)
    action.set_initial_targets(@hex_grid.get_selected_units)
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
