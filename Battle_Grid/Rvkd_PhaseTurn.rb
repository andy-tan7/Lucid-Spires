#==============================================================================
# Grid Shift Phase Turn Battle System - Turn Ordering
#------------------------------------------------------------------------------
#  This script handles the implementation of time slots, initiative and delay.
#==============================================================================

module PhaseTurn
  PHASE_DURATION = 100
  INITIAL_TURN_SPAN = 20
  DEFAULT_RESET_TIME = 20

  def self.setup
    init_members
  end

  def self.current_time ; return @current_time ; end
  def self.current_event ; return @current_event ; end

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
        if can_insert(@schedule[index], @schedule[index + 1], event)
          @schedule.insert(index + 1, event)
        else
          index += 1
        end
      end
      @schedule.push(event) if event.time > @schedule.last.time
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

  def self.can_insert(first, second, add)
    return true if first.time < add.time && add.time < second.time
    return false
  end

  def self.p_schedule
    return unless @current_event
    p("Schedule from #{@current_time} ---------------------------------------")
    cur = @current_event
    p([cur.battler.name, cur.time, cur.type, cur.unit_type])
    @schedule.each {|ts|
      next unless ts.subject
      p("#{ts.battler.name}, #{ts.time}, #{ts.type}, #{ts.unit_type}")
    }
    p("----------------------------------------------------------------------")
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

  def subject ; nil ; end
  def phase ; timeslot / PhaseTurn::Calc::PHASE_DURATION ; end
  def type ; :event ; end
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

  def subject ; @battler end
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
# ■ Game_Action
#=============================================================================
class Game_Action

  # calculate the time it takes before the action is executed.
  # typically 0. Affects when the TimeSlotAction is enqueued in the turn list.
  def prep_time
    time = item.prep_time
    fixed = item.prep_fixed
    if fixed
      return time # return the flat time if it cannot be modified
    else
      return time # return the time adjusted with speed (TODO)
    end
  end

  def reset_time
    time = item.reset_time
    fixed = item.reset_fixed
    if fixed
      return time # return the flat time if it cannot be modified
    else
      return time # return the time adjusted with speed (TODO)
    end
  end

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
    PhaseTurn.set_grid(@hex_grid)
  end

  alias rvkd_phaseturn_scb_post_start post_start
  def post_start
    rvkd_phaseturn_scb_post_start
    $game_party.setup_grid_positions(@hex_grid)
    @hex_grid.set_phase(:idle)

    test_pos = []
    @hex_grid.all_tiles.each do |tile|
      if tile.occupied?
        test_pos.push([tile.unit_contents[0].name], tile.coordinates_rc)
      end
    end
    p("test pos: #{test_pos}")

    next_command
  end

  alias rvkd_phaseturn_scb_create_spriteset create_spriteset
  def create_spriteset
    rvkd_phaseturn_scb_create_spriteset
    @hex_grid = @spriteset.create_grid
  end

  def current_time ; PhaseTurn.current_time end

  alias rvkd_phaseturn_scb_sac_selection start_actor_command_selection
  def start_actor_command_selection
    rvkd_phaseturn_scb_sac_selection
    BattleManager.input_start
    @hex_grid.set_phase(:input)
  end

  # override to delete
  def start_party_command_selection ; end

  # override ------------------------------------------------------------------
  def next_command
    event = BattleManager.next_command
    if event
      PhaseTurn.p_schedule
      case event.type
      when :event
        #environmental?
      when :turn
        # process inputs
        if event.battler.is_a?(Game_Actor)
          event.battler.make_actions
          start_actor_command_selection
        elsif event.battler.is_a?(Game_Enemy)
          queue_enemy_next_turn(event)
        end
      when :action
        # process execution
        @party_command_window.close
        @actor_command_window.close
        @status_window.unselect
        @subject = nil
        BattleManager.action_start
      end
    end
  end

  def queue_enemy_next_turn(time_slot_event)
    enemy = time_slot_event.battler
    enemy.make_actions

    action = enemy.actions[0]

    prep_time = action.prep_time
    reset_time = action.reset_time

    exec_time = current_time + prep_time
    next_turn_time = exec_time + reset_time

    temp_action = Rvkd_TimeSlotAction.new(exec_time, enemy, action)
    temp_next_turn = Rvkd_TimeSlotTurn.new(next_turn_time, enemy)
    PhaseTurn.insert_timeslot_event(temp_action)
    PhaseTurn.insert_timeslot_event(temp_next_turn)
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

  # override
  def process_action
    return if scene_changing?
    if !@subject || !@subject.current_action
      phase_event = PhaseTurn.current_event
      @subject = phase_event.subject if phase_event && phase_event.subject
    end
    return turn_end unless @subject

    if @subject.current_action
      @subject.current_action.prepare
      if @subject.current_action.valid?
        @status_window.open
        execute_action
      end
      @subject.remove_current_action
    end
    process_action_end unless @subject.current_action
  end

  # override
  def process_action_end
    @subject.on_action_end
    refresh_status
    @log_window.display_auto_affected_status(@subject)
    @log_window.wait_and_clear
    @log_window.display_current_state(@subject)
    @log_window.wait_and_clear
    BattleManager.judge_win_loss
    next_command
  end

end # Scene_Battle

#=============================================================================
# ■ BattleManager
#=============================================================================
class << BattleManager

  alias rvkd_phaseturn_bmg_init_members init_members
  def init_members
    rvkd_phaseturn_bmg_init_members
    @current_event = nil
    PhaseTurn.setup
  end

  # override turn_start
  # def turn_start
  #   @phase = :turn
  #   clear_actor
  #   $game_troop.increase_turn
  #   PhaseTurn.start_new_phase($game_party.members + $game_troop.members)
  # end

  # override actor
  def actor
    return @current_event.battler if @current_event.battler.actor?
    return nil
  end

  # override next_command
  def next_command
    unless @current_event
      PhaseTurn.start_new_phase($game_party.members + $game_troop.members)
    end

    @current_event = PhaseTurn.next_event
    #@actor_index = $game_party.members.index(@current_event.battler)
    return @current_event
  end

  def current_event ; return @current_event ; end
  def current_subject ; return @current_event.subject ; end

  def action_start
    turn_start
  end

  # override input_start
  def input_start
    @phase = :input
  end

  # override turn_start
  def turn_start
    @phase = :turn
    clear_actor
    $game_troop.increase_turn
  end

  def init_party_positions
    $game_party.battle_members.each do |member|
      member.set_grid_coordinates(*($game_party.grid_positions[member.id]))
    end
  end

end

#=============================================================================
# ■ Game_Battler
#=============================================================================
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
# ■ Game_Enemy
#=============================================================================
class Game_Enemy < Game_Battler

  alias rvkd_phaseturn_gen_make_actions make_actions
  def make_actions
    rvkd_phaseturn_gen_make_actions

  end

end


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
