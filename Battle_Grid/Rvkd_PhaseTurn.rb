#==============================================================================
# Grid Shift Phase Turn Battle System - Turn Ordering
#------------------------------------------------------------------------------
#  This script handles the implementation of time slots, initiative and delay.
#==============================================================================

module PhaseTurn
  PHASE_DURATION = 100
  INITIAL_TURN_SPAN = 20
  DEFAULT_RESET_TIME = 20

  module Calc

    # return whether the candidate should be inserted here.
    def self.can_insert(first, second, add)
      return true if first.time < add.time && add.time < second.time
      return false
    end

  end


  def self.setup
    init_members
  end

  def self.init_members
    @schedule = []
    @all_battlers = []
    @current_time = 0
    @current_event = nil
    @hex_grid = []
  end

  def self.set_grid(hex_grid)
    @hex_grid = hex_grid
  end

  def self.remove_grid_unit(unit)
    @hex_grid.remove_unit(unit)
  end

  def self.insert_timeslot_event(event)
    raise "Event time is before current time" if event.time < current_time
    # Add to the very start if there is no preparation time.
    if event.time == current_time
      @schedule.unshift(event)

    # Append if there is only one object.
    elsif @schedule.size == 1
      @schedule.push(event)

    # Find the appropriate insertion point.
    else
      index = 0
      while (index + 1) < @schedule.size
        if Calc.can_insert(@schedule[index], @schedule[next_index], event)
          @schedule.insert(next_index, event)
          return true
        else
          index += 1
        end
      end
      return false
    end
  end

  def self.start_new_phase(members, reset_timeslots = true)
    if reset_timeslots
      @schedule = calc_phase_start_order(members)
    end
  end

  def self.next_event
    @current_event = @schedule.shift
    return nil if !@current_event

    @current_time = @current_event.time
    p_schedule
    return @current_event
  end

  # supply a troop of units. Dead units are not used in the calculation.
  def self.calc_phase_start_order(all_members)
    pairs = recalculate_initiative(all_members)

    # sort array by initial turn slot (ascending) and return an array of
    # time slot turns.
    timeslot_turns = []
    pairs.sort_by {|_,spds| spds[1] }.each do |pair|
      timeslot_turns.push(Rvkd_TimeSlotTurn.new(pair[1][1], pair[0]))
    end
    return timeslot_turns
  end # calc_phase_start_order

  def self.recalculate_initiative(all_members)
    # populate an array of unit-speed pairs for the entire actionable troop.
    # speeds variable will be an array [spd stat, initial calc]
    all_members = all_members.select {|member| member.alive? }
    pairs = {}
    all_members.each {|unit| pairs[unit] = [unit.agi, nil] }
    slowest_unit = pairs.collect{|p| p[1] }.inject{|x,y| [x,y].min }

    # calculate initial speed factors, scaled to the initial turn span.
    d = [slowest_unit[0], INITIAL_TURN_SPAN].min
    pairs.each_value {|spds| spds[1] = INITIAL_TURN_SPAN / (spds[0].to_f / d) }

    return pairs
  end

  def self.p_schedule
    p("Schedule from #{@current_time}")
    cur = @current_event
    p([cur.battler.name, cur.time, cur.type, cur.unit_type])
    @schedule.each {|turn|
      p([turn.battler.name, turn.time, turn.type, turn.unit_type])
    }
  end

end # module PhaseTurn

#=============================================================================
# ■ Rvkd_TimeSlotEvent
#=============================================================================
class Rvkd_TimeSlotEvent
  attr_reader :time
  def initialize(time)
    @time = time
  end

  def phase ; timeslot / PhaseTurn::Calc::PHASE_DURATION end
  def type ; :event end
end

#=============================================================================
# ■ Rvkd_TimeSlotTurn
#=============================================================================
class Rvkd_TimeSlotTurn < Rvkd_TimeSlotEvent
  attr_reader :battler
  def initialize(time, battler)
    super(time)
    @battler = battler    # Game_Battler
  end

  def type ; :turn end

  def unit_type
    return Game_Actor if battler.is_a?(Game_Actor)
    return Game_Enemy if battler.is_a?(Game_Enemy)
    return nil
  end

end

#=============================================================================
# ■ Rvkd_TimeSlotAction
#=============================================================================
class Rvkd_TimeSlotAction < Rvkd_TimeSlotTurn
  attr_reader :action

  def initialize(time, battler, action)
    super(time, battler)
    @action = action  # Game_Action
  end

    def type ; :action end
end

#=============================================================================
# ■ Scene_Battle
#=============================================================================
class Scene_Battle < Scene_Base

  alias rvkd_phaseturn_scb_start start
  def start
    rvkd_phaseturn_scb_start
    # BattleManager.init_party_positions
    @current_action = nil
    @counter = 0
    $game_troop.setup_grid_positions(@hex_grid)
    $game_troop.members.each {|member| msgbox_p([member.x, member.y])}
    PhaseTurn.set_grid(@hex_grid)
  end

  alias rvkd_phaseturn_scb_create_spriteset create_spriteset
  def create_spriteset
    rvkd_phaseturn_scb_create_spriteset
    @hex_grid = @spriteset.create_grid
  end

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

  def current_time ; PhaseTurn.current_time end

  def on_target_ok
    # primitive set: need to calculate area from ability with anchor point
    BattleManager.actor.input.set_target_region([@actor_window.index])
    create_timeslot_action(BattleManager.actor.input)
    @target_window.cancel_target_selection(BattleManager.actor)
  end

  def on_target_cancel
    p("c")
    @target_window.deactivate
    @target_window.hide
    @target_window.cancel_target_selection(BattleManager.actor)
    case @actor_command_window.current_symbol
    when :attack
      @actor_command_window.activate
    when :skill
      @skill_window.activate
    when :item
      @item_window.activate
    end
  end

  def select_target_selection(battler, usable_item)
    @target_window.refresh
    @target_window.show.activate
    @target_window.setup_range(battler, usable_item)
  end

  # override functions that begin target selection ----------------------------
  def command_attack
    usable_item = $data_skills[BattleManager.actor.attack_skill_id]
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

  # override ------------------------------------------------------------------
  def next_command
    event = BattleManager.next_command
    if event
      case event.type
      when :event
        #environmental?
      when :turn
        # process inputs
        start_actor_command_selection if event.battler.is_a?(Game_Actor)
      when :action
        # process execution
      end
    end
  end

  # build a Rvkd_TimeSlotAction and enqueue it in the turn list. Needs:
  # current time slot
  # setup time for action
  # keep track of next delay on actor
  def create_timeslot_action(actor, action)
    prep_time = action.prep_time
    reset_time = action.reset_time

    exec_time = current_time + prep_time
    next_turn_time = exec_time + reset_time

    temp_action = Rvkd_TimeSlotAction.new(exec_time, actor, action)
    temp_next_turn = Rvkd_TimeSlotTurn.new(next_turn_time, actor)

    # is this for display, or are these actions being used for real?

    # enqueue the action and the unit's next turn.
    PhaseTurn.insert_timeslot_event(temp_action)
    PhaseTurn.insert_timeslot_event(temp_next_turn)
  end


end # Scene_Battle

#=============================================================================
# ■ BattleManager
#=============================================================================
module BattleManager

  class << self

    alias rvkd_phaseturn_bmg_init_members init_members
    def init_members
      rvkd_phaseturn_bmg_init_members
      @current_event = nil
      PhaseTurn.setup
    end

    # override turn_start
    def turn_start
      @phase = :turn
      clear_actor
      $game_troop.increase_turn
      PhaseTurn.start_new_phase($game_party.members + $game_troop.members)
    end

    # override next_command
    def next_command
      unless @current_event
        PhaseTurn.start_new_phase($game_party.members + $game_troop.members)
      end

      @current_event = PhaseTurn.next_event
      @actor_index = $game_party.members.index(@current_event.battler)
      return @current_event
    end

    def init_party_positions
      $game_party.battle_members.each do |member|
        member.set_grid_coordinates(*($game_party.grid_positions[member.id]))
      end
    end

  end

end

class Game_Battler < Game_BattlerBase

  alias rvkd_phaseturn_gbt_initialize initialize
  def initialize
    @current_reset_time = 0
    rvkd_phaseturn_gbt_initialize
  end

  attr_reader :current_reset_time
  def set_reset_time(time)
    @current_reset_time = time
  end

end

#=============================================================================
# ■ Game_Action
#=============================================================================
class Game_Action

  # calculate the time it takes before the action is executed.
  # typically 0. Affects when the TimeSlotAction is enqueued in the turn list.
  def prep_time
    time = item.prep_time
    fixed = item.prep_fixed

    if fixed
      return time
    else
      return time
    end
  end

  def reset_time
    time = item.reset_time
    fixed = item.reset_fixed

    if fixed
      return time
    else
      return time
    end
  end


  attr_reader :target_grid
  def set_target_region(region)
    target_grid = region.is_a?(Array) ? region : []
  end

end # Game_Action

#=============================================================================
# ■ RPG::UsableItem
#=============================================================================
class RPG::UsableItem < RPG::BaseItem

  def prep_time
    return $1.to_i if self.note =~ /<prep[\s_]*:\s*(\d+)>/i
    return 0
  end

  # A fixed preparation time means it cannot be reduced with speed stats.
  def prep_fixed
    return true if self.note =~ /<fixed[\s_]*prep>/i
    return false
  end

  def reset_time
    return $1.to_i if self.note =~ /<reset[\s_]*:\s*(\d+)>/i
    return PhaseTurn::DEFAULT_RESET_TIME
  end

  # If the delay after an action cannot be reduced with speed stats.
  def reset_fixed
    return true if self.note =~ /<fixed[\s_]*reset>/i
    return false
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
    when 0 # none
      return :none
    when 1, 2, 3, 4, 5, 6 # enemy
      return :enemy
    when 7, 8 # one ally
      return :ally
    when 9, 10
      return :ally_dead
    when 11 # the user
      return :self
    end
  end

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

  def ok_enabled?
    true
  end

  def cancel_enabled?
    true
  end

  def setup_range(battler, item)
    origin = [battler.grid_row, battler.grid_col]
    interact_tiles = Revoked::Grid.make_interact(@battle_grid, origin, item)
    available = interact_tiles[0]
    area = interact_tiles[1]
    cursor_rc = Revoked::Grid.auto_cursor(@battle_grid, origin, available, item)
    msgbox_p(cursor_rc)

    @battle_grid.setup_target_selection(cursor_rc, available, area)
  end

  def cancel_target_selection(actor)
    @battle_grid.cancel_target_selection(actor)
  end

  def process_handling
    return unless active
    return process_ok     if ok_enabled?     && Input.trigger?(:C)
    return process_cancel if cancel_enabled? && Input.trigger?(:B)
  end

  def process_ok
    targets = @battle_grid.selected_units
  end

end # Window_GridTarget
