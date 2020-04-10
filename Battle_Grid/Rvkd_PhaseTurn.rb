#==============================================================================
# Grid Shift Phase Turn Battle System - Turn Ordering
#------------------------------------------------------------------------------
#  This script handles the implementation of time slots, initiative and delay.
#==============================================================================

module PhaseTurn

  def self.setup


  end

  def self.init_members


  end




  module Calc

    PHASE_DURATION = 100
    INITIAL_TURN_SPAN = 20
    DELAY_DEFAULT = 20

    # supply a troop of units. Dead units are not used in the calculation.
    def self.calc_phase_start_order(all_members)
      return nil if !all_members.is_a(Array)

      # populate an array of unit-speed pairs for the entire actionable troop.
      # speeds variable will be an array [spd stat, initial calc]
      pairs = {}
      all_members.each {|unit| pairs[unit] = [unit.agi, nil]}
      slowest_unit = all_members.collect{|p| p[1]}.inject{|x,y| [x,y].min}

      # calculate initial speed factors, scaled to the initial turn span.
      div_factor = [slowest_unit[0], INITIAL_TURN_SPAN].min
      all_members.each_value do |spds|
        spds[1] = INITIAL_TURN_SPAN / (spds[0].to_f / div_factor)
      end

      # sort array by initial turn slot (ascending) and return an array of
      # time slot turns.
      timeslot_turns = []
      all_members.sort_by {|unit,spds| spds[1]}.each do |pair|
        timeslot_events.push(Rvkd_TimeSlotTurn.new(pair[0], pair[1][1]))
      end
      return timeslot_turns
    end

  end # module PhaseTurn::Calc

end # module PhaseTurn


class Rvkd_TimeSlotEvent

  attr_reader :time
  def initialize(time)
    @time = time
  end

  def phase ; timeslot / PhaseTurn::Calc::PHASE_DURATION

end

class Rvkd_TimeSlotTurn < Rvkd_TimeSlot

  attr_reader :battler

  def initialize(battler, time)
    super(time)
    @battler = battler    # Game_Battler
  end

end

class Rvkd_TimeSlotAction < Rvkd_TimeSlotTurn

  attr_reader :action

  def initialize(battler, time, action)
    super(battler, time)
    @action = action  # Game_Action
  end

end
