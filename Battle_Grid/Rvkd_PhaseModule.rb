#==============================================================================
# Grid Shift Phase Turn Battle System - Phase Module
#------------------------------------------------------------------------------
#  This script handles and abstracts phase and time-related calculations.
#==============================================================================
# ■ Phase
#==============================================================================
module Phase
  #---------------------------------------------------------------------------
  # * Constants
  #---------------------------------------------------------------------------
  module Config

    PHASE_DURATION = 100
    PHASE_INSERT_TIME = 65
    INITIAL_TURN_SPAN = 20
    DEFAULT_RESET_TIME = 20
    PHASE_LABEL = "Phase End"

    Bar = {
      :x => 0,
      :y => 4,
      :bar_init_x => -250,
      :short_bar_offset_x => -152,
      :hidden_bar_offset_x => -116,
      :event_bar_offset_x => -32,

      :time_width => 36,
      :time_font_size => 18,

      :face_x => 36,
      :face_y => -1,

      :item_icon_x => 66,
      :item_icon_y => 0,

      :item_name_a => 255,
      :item_name_a_init => 0,

      :item_name_x => 92,
      :item_name_y => 0,
      :item_name_width => 180,
      :item_name_font_size => 20,

      :bar_width => 300,
      :bar_height => 27,
      :top_offset => 8,

      :bar_tone => {
        :regular => Tone.new,
        :gold => Tone.new(168, 120, 16, 64),
        :event => Tone.new(0, 16, 8, 8),
        :target => Tone.new(64, 64, 64, 64)
      }
    }

  end
end # module Phase

class << Phase
  #---------------------------------------------------------------------------
  # Calculate troop order. Dead units are not used in the calculation.
  #---------------------------------------------------------------------------
  def calc_phase_start_order(all_members)
    pairs = recalculate_initiative_factors(all_members)
    # Sort by initial turn slot (ascending) and return an array of turn events.
    timeslot_turns = []
    pairs.sort_by {|_,spds| spds[1] }.each do |pair|
      timeslot_turns.push(Rvkd_TimeSlotTurn.new(pair[1][1], pair[0]))
    end
    return timeslot_turns
  end

  #---------------------------------------------------------------------------
  # Calculate the delay until every member's first turn.
  #---------------------------------------------------------------------------
  def recalculate_initiative(all_members)
    # populate an array of unit-speed pairs for the entire actionable troop.
    # speeds variable will be an array [spd stat, initial calc]
    all_members = all_members.select {|member| member.alive? }
    pairs = {}
    all_members.each {|unit| pairs[unit] = [unit.agi, nil] }
    slowest_unit = pairs.collect{|p| p[1] }.inject{|x,y| [x,y].min }

    # Calculate initial speed factors, scaled to the initial turn span.
    d = [slowest_unit[0], INITIAL_TURN_SPAN].min
    pairs.each_value {|spds| spds[1] = INITIAL_TURN_SPAN / (spds[0].to_f / d) }

    return pairs
  end

  #---------------------------------------------------------------------------
  # Calculate the delay until every member's first turn.
  #---------------------------------------------------------------------------
  def recalculate_initiative_factors(all_members)
    # Order all battlers by agility.
    all_members = all_members.select {|member| member.alive? }

    agilities = all_members.collect {|unit| unit.agi }
    low = agilities.min
    diff = agilities.max - low

    pairs = {} # Hash key: unit; value: [agility, initiative]
    # Calculate the speed ratios based on the highest and lowest agility.
    all_members.each do |unit|
      spd_ratio = 1 - (unit.agi - low).to_f / diff
      spd_factor = (1 + (9 * spd_ratio)).to_i
      pairs[unit] = [unit.agi, (spd_factor..(2 * spd_factor)).to_a.sample]
    end

    return pairs
  end

  #---------------------------------------------------------------------------
  # Create a set of actions for demoing player input results.
  # These actions are used to directly add to the schedule if confirmed.
  #---------------------------------------------------------------------------
  def create_temp_events(actor, action)
    exec_time = TurnManager.current_time + action.prep_time
    next_turn_time = exec_time + action.reset_time

    temp_action = Rvkd_TimeSlotAction.new(exec_time, actor, action)
    temp_next_turn = Rvkd_TimeSlotTurn.new(next_turn_time, actor)

    return [temp_action, temp_next_turn]
  end
  #---------------------------------------------------------------------------
  # Binary search for an insertion point of a time based on an array of times.
  #---------------------------------------------------------------------------
  def get_insertion_index(ins_time, times)
    # O(logn) solution
    lower = 0
    upper = times.length - 1

    return times.length if times.empty? || times.last < ins_time
    return 0 if times.first > ins_time

    while (lower <= upper)
      mid = (lower + upper) / 2
      if (times[mid] == ins_time)
        mid += 1 while (times[mid] == ins_time)
        return mid
      elsif (times[mid] < ins_time)
        return mid + 1 if (mid < times.length) && times[mid + 1] > ins_time
        lower = mid + 1
      elsif (times[mid] > ins_time)
        return mid if mid > 0 && times[mid - 1] < ins_time
        upper = mid - 1
      end
    end
    raise "did not find insertion index"
  end
end # module Phase

#==============================================================================
#
# ▼ End of File
#
#==============================================================================
