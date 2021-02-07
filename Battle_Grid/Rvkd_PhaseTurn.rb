#==============================================================================
# Grid Shift Phase Turn Battle System - Turn Ordering
#------------------------------------------------------------------------------
#  This script handles the implementation of time slots, initiative/delay, and
#  the handling for the event display bar.
#==============================================================================
# ■ TurnManager
#==============================================================================
module TurnManager
  def self.init_members
    @schedule = []
    @current_time = 0
    @current_event = nil
    @hex_grid = []
    @event_display = nil
    @phase_shift_event = nil
  end
end

class << TurnManager
  #---------------------------------------------------------------------------
  # * Public Instance Variables
  #---------------------------------------------------------------------------
  def current_time ; return @current_time ; end
  def current_event ; return @current_event ; end
  def phase_end_time ; @phase_shift_event ? @phase_shift_event.time : -1 ; end

  #---------------------------------------------------------------------------
  # * Object Initialization
  #---------------------------------------------------------------------------
  def setup
    init_members
  end

  # Keep reference of a hex grid.
  def set_grid(hex_grid)
    @hex_grid = hex_grid
  end

  # Initialize new battle phase
  def start_new_phase(members, reset_timeslots = true)
    if reset_timeslots
      @current_time = 0
      @schedule = Phase.calc_phase_start_order(members)
      @phase_shift_event = nil
      start_new_event_display

      # Decrement phase-duration states.
      all_members = $game_troop.members + $game_party.members
      all_members.each do |u|
        u.update_state_phases
        u.remove_states_auto(2)
      end
    end
  end

  def try_insert_phase_shift_event(time = Phase::Config::PHASE_DURATION)
    # Reveal the Phase Shift event once the phase nears its end.
    if @current_time > Phase::Config::PHASE_INSERT_TIME && !@phase_shift_event
      @phase_shift_event = Rvkd_TimeSlotEvent.new(time, true)
      insert_timeslot_event(@phase_shift_event)
      return true
    end
    return false
  end

  def action_valid?(a)
    return true if phase_end_time <= 0
    return @current_time + a.prep_time < phase_end_time && phase_end_time > 0
  end
  #---------------------------------------------------------------------------
  # * Add an event to both the turn schedule and the event display list.
  #---------------------------------------------------------------------------
  def insert_timeslot_event(event)
    return if event && event.time > phase_end_time && phase_end_time > 0

    insert_schedule_only(event)
    ins_at = 1 if event.time == @current_time
    ins_at ||= Phase.get_insertion_index(event.time,
      @event_display.get_times_array)

    add_display_unit_event(ins_at, event)
  end

  # Add an event only to the turn schedule.
  def insert_schedule_only(event)
    return if event && event.time > phase_end_time && phase_end_time > 0

    ins_at = 0 if event.time == @current_time
    ins_at ||= Phase.get_insertion_index(event.time,
      @schedule.collect {|e| e.time})

    @schedule.insert(ins_at, event)
  end

  # Change colour of events to show that their units are being targeted.
  def highlight_selected_unit_events(units)
    unhighlight_selected_unit_events
    all_members = $game_troop.members + $game_party.members
    units.each do |unit|
      @event_display.highlight_elements(unit) if all_members.include?(unit)
    end
  end
  def unhighlight_selected_unit_events
    @event_display.unhighlight_elements
  end
  #---------------------------------------------------------------------------
  # Shift the schedule, retrieve the next upcoming event and update time.
  #---------------------------------------------------------------------------
  def next_event
    @current_event = @schedule.shift
    return nil if !@current_event

    set_current_time(@current_event.time)
    return @current_event
  end
  #---------------------------------------------------------------------------
  # Pass a certain amount of phase time. Advances state progression on units.
  #---------------------------------------------------------------------------
  def set_current_time(time)
    last_time = @current_time
    @current_time = time

    elapsed = time - last_time
    all_members = $game_troop.members + $game_party.members
    elapsed.times do
      all_members.each do |u|
        u.update_state_turns
        u.remove_states_auto(2)
      end
    end
  end
  #---------------------------------------------------------------------------
  # Get an array of units within the set of tiles.
  #---------------------------------------------------------------------------
  def units_in_area(tiles)
    return Grid.units_in_area(@hex_grid, tiles)
  end

  #===========================================================================
  # Grid manipulation
  #---------------------------------------------------------------------------
  # * Remove a unit from the current grid, then remove its scheduled events.
  #---------------------------------------------------------------------------
  def remove_grid_unit(unit)
    @hex_grid.remove_unit(unit)
    remove_unit_events(unit)
  end

  # Remove all events where the unit is the subject.
  def remove_unit_events(unit)
    rem_events = @schedule.select {|event| event.subject == unit}
    @schedule -= rem_events
    remove_multiple_events(rem_events)
  end
  #---------------------------------------------------------------------------
  # Relocate a unit.
  #---------------------------------------------------------------------------
  def move_unit(unit, new_tiles)
    return unless @hex_grid

    @hex_grid.relocate_unit_tiles(unit, new_tiles)
  end

  def move_command(actor)
    move_unit(actor, actor.current_action.targeted_grid)
  end

  # Debug method
  def p_schedule
    return unless @current_event
    p("Schedule from #{@current_time} ---------------------------------------")
    cur = @current_event
    p("> #{cur.battler.name}, #{cur.time}, #{cur.type}, #{cur.unit_type}")
    @schedule.each {|ts|
      next unless ts.subject
      p("#{ts.battler.name}, #{ts.time}, #{ts.type}, #{ts.unit_type}")
    }
    p("----------------------------------------------------------------------")
  end
end # module TurnManager

#==============================================================================
# ■ PhaseTurn - Event Display Bar
#==============================================================================
class << TurnManager

  #---------------------------------------------------------------------------
  # * Initialize battle event display.
  #---------------------------------------------------------------------------
  def create_event_display(viewport)
    @event_display = Rvkd_EventDisplay.new(viewport)
    return @event_display
  end

  def start_new_event_display
    @event_display.reset_display
    @schedule.each_with_index do |event, index|
      case event.type
      when :event  ; add_display_global_event(index, event)
      when :turn   ; add_display_unit_event(index, event)
      when :action ; add_display_unit_event(index, event)
      end
    end
  end

  def update_event_display
    @event_display.update_display
  end

  def refresh_event_display_list
    @event_display.refresh_list(@current_time)
  end
  #---------------------------------------------------------------------------
  # Traverse the event display to update event action visibility.
  #---------------------------------------------------------------------------
  def refresh_revealed_events
    @event_display.refresh_revealed_events
  end
  #---------------------------------------------------------------------------
  # * Add events
  #---------------------------------------------------------------------------
  def add_display_global_event(index, event, tone = :regular)
    @event_display.create_phase_shift_event(event, index)
  end

  def add_display_unit_event(index, event, tone = :regular)
    @event_display.create_unit_event(event, index, tone)
  end

  def remove_display_event(turn)
    @event_display.remove_display_element(turn.event) if turn
  end

  def remove_multiple_events(rem_events)
    @event_display.remove_multiple_elements(rem_events)
  end
  #---------------------------------------------------------------------------
  # Process completion of the current displayed event.
  #---------------------------------------------------------------------------
  def finish_current_event
    @event_display.remove_display_element(@current_event)
  end
  #---------------------------------------------------------------------------
  # Keep track of known moving display elements.
  #---------------------------------------------------------------------------
  def anim_track_element(element)
    @event_display.anim_track_element(element)
  end

  def anim_untrack_element(element)
    @event_display.anim_untrack_element(element)
  end
  #---------------------------------------------------------------------------
  # * Demo selected actions.
  #---------------------------------------------------------------------------
  def indicate_player_selected_event(event)
    ins_at = event.time == @current_time ? 1 : nil
    ins_at ||= Phase.get_insertion_index(event.time,
      @event_display.get_times_array)
    if event && event.time > phase_end_time && phase_end_time > 0
      @temp_display_action = add_display_unit_event(ins_at, event, :red)
    else
      @temp_display_action = add_display_unit_event(ins_at, event, :gold)
    end
  end

  # Demo the player's next turn if they confirm the indicated action.
  def indicate_player_selected_next_turn(event)
    ins_at = event.time == @current_time ? 1 : nil
    ins_at ||= Phase.get_insertion_index(event.time,
      @event_display.get_times_array)
    if event && event.time > phase_end_time && phase_end_time > 0
      @temp_display_next_turn = nil
    else
      @temp_display_next_turn = add_display_unit_event(ins_at, event, :gold)
    end
  end

  # Remove any temporary demo actions.
  def cancel_indicated_events
    remove_display_event(@temp_display_action)
    remove_display_event(@temp_display_next_turn)
    @temp_display_action = nil
    @temp_display_next_turn = nil
  end

  def get_temp_events
    [@temp_display_action, @temp_display_next_turn].compact
  end
  #---------------------------------------------------------------------------
  # Change the background shadow tones for the temp events.
  #---------------------------------------------------------------------------
  def set_temp_tone(tone_symbol = :regular)
    get_temp_events.each {|temp| temp.set_tone(tone_symbol) }
  end
  #---------------------------------------------------------------------------
  # Retrieve the corresponding display element for an event.
  #---------------------------------------------------------------------------
  def get_display_element_from_event(event)
    return @event_display.get_display_element_from_event(event)
  end

end # module TurnManager // Event Display Bar

#=============================================================================
# ■ BattleManager
#=============================================================================
class << BattleManager
  #---------------------------------------------------------------------------
  # * Public Instance Variables
  #---------------------------------------------------------------------------
  attr_reader :phase
  def current_event   ; return @current_event         ; end
  def current_subject ; return @current_event.subject ; end
  #---------------------------------------------------------------------------
  # * Object Initialization
  #---------------------------------------------------------------------------
  alias rvkd_phaseturn_bmg_init_members init_members
  def init_members
    rvkd_phaseturn_bmg_init_members
    @current_event = nil
    TurnManager.setup
  end
  #---------------------------------------------------------------------------
  # Set the initial positions of all player party members.
  #---------------------------------------------------------------------------
  def init_party_positions
    $game_party.battle_members.each do |member|
      member.set_grid_coordinates(*($game_party.grid_positions[member.id]))
    end
  end
  #---------------------------------------------------------------------------
  # Override - get the battler of the current event if it is an actor.
  #---------------------------------------------------------------------------
  def actor
    return @current_event.battler if @current_event.battler.actor?
    return nil
  end
  #---------------------------------------------------------------------------
  # Process the start of an action turn.
  #---------------------------------------------------------------------------
  def action_start
    turn_start
  end
  #---------------------------------------------------------------------------
  # Override - Start command input
  #---------------------------------------------------------------------------
  def input_start
    @phase = :input
  end
  #---------------------------------------------------------------------------
  # Override - Start turn
  #---------------------------------------------------------------------------
  def turn_start
    @phase = :turn
    clear_actor
    $game_troop.increase_turn
  end
  #---------------------------------------------------------------------------
  # Override - get the next event in the schedule, or start a new phase.
  #---------------------------------------------------------------------------
  def next_command
    unless @current_event
      TurnManager.start_new_phase($game_party.members + $game_troop.members)
    end

    @current_event = TurnManager.next_event
    return @current_event
  end

end # module BattleManager

#=============================================================================
# ■ Scene_Battle
#=============================================================================
class Scene_Battle < Scene_Base

  #---------------------------------------------------------------------------
  # Start Processing
  #---------------------------------------------------------------------------
  alias rvkd_phaseturn_scb_start start
  def start
    rvkd_phaseturn_scb_start
    # BattleManager.init_party_positions
    @current_action = nil
    @counter = 0
    $game_troop.setup_grid_positions(@hex_grid)
    TurnManager.set_grid(@hex_grid)
  end
  #---------------------------------------------------------------------------
  # Post-Start Processing
  #---------------------------------------------------------------------------
  alias rvkd_phaseturn_scb_post_start post_start
  def post_start
    rvkd_phaseturn_scb_post_start
    $game_party.setup_grid_positions(@hex_grid)
    @hex_grid.set_mode(:idle)

    test_pos = []
    @hex_grid.all_tiles.each do |tile|
      if tile.occupied?
        test_pos.push([tile.unit_contents[0].name], tile.coordinates_rc)
      end
    end
    p("test pos: #{test_pos}")

    next_command
  end

  #---------------------------------------------------------------------------
  # Frame update
  #---------------------------------------------------------------------------
  alias rvkd_phaseturn_bar_scb_update_basic update_basic
  def update_basic
    rvkd_phaseturn_bar_scb_update_basic
    TurnManager.update_event_display
  end

  #---------------------------------------------------------------------------
  # Create Sprite Set
  #---------------------------------------------------------------------------
  alias rvkd_phaseturn_scb_create_spriteset create_spriteset
  def create_spriteset
    rvkd_phaseturn_scb_create_spriteset
    @hex_grid = @spriteset.create_grid
    @event_display = @spriteset.create_event_display
  end
  #---------------------------------------------------------------------------
  # Start Actor Command Selection
  #---------------------------------------------------------------------------
  alias rvkd_phaseturn_scb_sac_selection start_actor_command_selection
  def start_actor_command_selection
    rvkd_phaseturn_scb_sac_selection
    BattleManager.input_start
    @hex_grid.set_mode(:input)
  end

  # overriden to delete original method body.
  def start_party_command_selection ; end
  #---------------------------------------------------------------------------
  # Get the current time slot.
  #---------------------------------------------------------------------------
  def current_time ; TurnManager.current_time end
  #---------------------------------------------------------------------------
  # Skip frames to simulate a mid-battle wait.
  #---------------------------------------------------------------------------
  def telegraph_ability(time = 30)
    time.times { update_basic }
  end
  #---------------------------------------------------------------------------
  # Override - process the next event on the phase turn schedule.
  #---------------------------------------------------------------------------
  def next_command
    event = BattleManager.next_command
    if event
      telegraph_ability(15) if TurnManager.try_insert_phase_shift_event
      #p(event.time)
      #TurnManager.p_schedule
      case event.type
      when :event
        if event.phase_shift?
          TurnManager.start_new_phase($game_party.members + $game_troop.members)
        end
        #environmental?
      when :turn
        # process inputs
        if event.battler.is_a?(Game_Actor)
          event.battler.make_actions
          start_actor_command_selection
        elsif event.battler.is_a?(Game_Enemy)
          queue_enemy_next_turn(event)
          next_command
        end
      when :action
        # process execution
        @party_command_window.close
        @actor_command_window.close
        @status_window.unselect
        @subject = nil
        start_next_action(event)
      end
    else
      msgbox_p("no events in command list")
    end
  end
  #---------------------------------------------------------------------------
  # Begin executing the action event.
  #---------------------------------------------------------------------------
  def start_next_action(event)
    telegraph_ability(15)
    display = TurnManager.get_display_element_from_event(event)
    unless display.player_revealed
      display.reveal_action
      telegraph_ability(15)
    end

    BattleManager.action_start
    event.battler.set_actions([event.action])
  end
  #---------------------------------------------------------------------------
  # Override - process the current subject's action.
  #---------------------------------------------------------------------------
  def process_action
    return if scene_changing?
    if !@subject || !@subject.current_action
      phase_event = TurnManager.current_event
      @subject = phase_event.subject if phase_event && phase_event.subject
    end
    return turn_end unless @subject

    if @subject.current_action
      @subject.current_action.prepare
      if @subject.current_action
        if @subject.current_action.valid?
          @status_window.open
          execute_action
        end
      end
      @subject.remove_current_action
    end
    process_action_end unless @subject.current_action
  end
  #---------------------------------------------------------------------------
  # Override - finish the current subject's action.
  #---------------------------------------------------------------------------
  def process_action_end
    @subject.on_action_end
    refresh_status
    @log_window.display_auto_affected_status(@subject)
    @log_window.wait_and_clear
    @log_window.display_current_state(@subject)
    @log_window.wait_and_clear
    TurnManager.finish_current_event
    BattleManager.judge_win_loss
    next_command if BattleManager.phase
  end
  #---------------------------------------------------------------------------
  # Add the enemy battler's action and next turn to the schedule.
  #---------------------------------------------------------------------------
  def queue_enemy_next_turn(time_slot_event)
    enemy = time_slot_event.battler
    action_array = enemy.prepare_actions

    action = action_array[0]

    prep_time = action.prep_time
    reset_time = action.reset_time

    exec_time = current_time + prep_time
    next_turn_time = exec_time + reset_time

    temp_action = Rvkd_TimeSlotAction.new(exec_time, enemy, action)
    temp_next_turn = Rvkd_TimeSlotTurn.new(next_turn_time, enemy)

    telegraph_ability(15)
    # Add the new action to the event chain.
    TurnManager.insert_timeslot_event(temp_action)
    # Display the telegraphed move if enabled -- otherwise just wait frames.
    Sound.play_grid_event_add
    telegraph_ability
    # Remove the current turn event.
    TurnManager.finish_current_event
    # Add the unit's next turn to the event chain.
    TurnManager.insert_timeslot_event(temp_next_turn)
  end
  #---------------------------------------------------------------------------
  # Build a Rvkd_TimeSlotAction and enqueue it in the turn list.
  # Needs: (1) current time, (2) setup time for action, (3) actor next delay
  #---------------------------------------------------------------------------
  def queue_actor_next_turn(actor, action)
    temp = TurnManager.get_temp_events
    TurnManager.set_temp_tone(:regular)

    temp[0].event.set_action(action) if temp[0]
    # enqueue the action and the unit's next turn.
    # Add the new action to the event chain.
    TurnManager.insert_schedule_only(temp[0].event) if temp[0]
    # Display the telegraphed move if enabled -- otherwise just wait frames.
    telegraph_ability
    # Remove the current turn event.
    TurnManager.finish_current_event
    # Add the unit's next turn to the event chain.
    TurnManager.insert_schedule_only(temp[1].event) if temp[1]
  end
end # Scene_Battle

#=============================================================================
# ■ Rvkd_EventDisplay
#------------------------------------------------------------------------------
# The visual list of event elements, ordered by their time of exeucution.
# This class handles creation and deletion of all event elements.
#=============================================================================
class Rvkd_EventDisplay
  #---------------------------------------------------------------------------
  # * Public Instance Variables
  #---------------------------------------------------------------------------
  attr_reader :animated_elements
  #---------------------------------------------------------------------------
  # * Object Initialization
  #---------------------------------------------------------------------------
  def initialize(viewport)
    @viewport = viewport
    reset_display
  end

  # Reset the event display, disposing all events.
  def reset_display
    dispose_events if @events
    @events = []
    @animated_elements = []
    @highlighted_elements = []
  end
  #---------------------------------------------------------------------------
  # Create a visual display bar for a unit's turn or action event.
  #---------------------------------------------------------------------------
  def create_unit_event(event, index, tone)
    index ||= Phase.get_insertion_index(event.time, get_times_array)
    element = Rvkd_EventDisplay_Element.new(event, @viewport, index, tone)
    add_display_element(element)
  end
  def create_phase_shift_event(event, index)
    index ||= Phase.get_insertion_index(event.time, get_times_array)
    element = Rvkd_EventDisplay_Element.new(event, @viewport, index, :event)
    add_display_element(element)
  end
  #---------------------------------------------------------------------------
  # Add a turn display element to the event list.
  #---------------------------------------------------------------------------
  def add_display_element(element)
    element.index ||= @events.length
    @events.insert(element.index, element)
    @events.each_with_index {|ev, i| ev.change_index(i) }
    return element
  end
  #---------------------------------------------------------------------------
  # Remove a single element from the element list.
  #---------------------------------------------------------------------------
  def remove_display_element(element)
    index = @events.find_index {|ev| ev.event == element }
    #raise "attempt to delete element not in the event list." unless index
    return unless index

    @animated_elements.delete(@events[index])
    @events[index].dispose
    @events.delete_at(index)

    @events.each_with_index {|ev, i| ev.change_index(i)}
  end

  # Remove multiple (potentially non-consecutive) elements and repair indices.
  # TODO: merge with single delete later.
  def remove_multiple_elements(events)
    rem_elems = []
    events.each {|ev| rem_elems.push(@events.find {|e| e.event == ev})}
    rem_elems.compact.each do |elem|
      @animated_elements.delete(elem)
      elem.dispose
      @events.delete(elem)
    end
    @events.each_with_index {|ev, i| ev.change_index(i) if ev.index != i}
  end

  # Recursively dispose of all elements in the display.
  def dispose_events
    @events.each {|event| event.dispose }
  end
  #---------------------------------------------------------------------------
  # Update any moving elements (slide animation).
  #---------------------------------------------------------------------------
  def update_display
    return unless @animated_elements.any?
    @animated_elements.reverse_each {|element| element.update }
  end

  # Reveal revealable events and hide newly-hidden events.
  def refresh_revealed_events
    to_reveal = []
    to_hide = []
    @events.each do |event|
      if event.player_revealed != event.event.revealed?
        event.player_revealed ? to_reveal << event : to_hide << event
      end
    end
    to_reveal.each {|event| event.reveal_action }
    to_hide.each {|event| event.hide_action }
  end
  #---------------------------------------------------------------------------
  # Get the array of event times (automatically sorted in increasing order).
  #---------------------------------------------------------------------------
  def get_times_array
    return @events.collect {|element| element.event.time }
  end
  #---------------------------------------------------------------------------
  # Fetch an element from a given schedule event.
  #---------------------------------------------------------------------------
  def get_display_element_from_event(event)
    return @events.find {|ev| ev.event == event }
  end
  #---------------------------------------------------------------------------
  # Change the colour of an event item to show it being selected / targeted.
  #---------------------------------------------------------------------------
  def highlight_elements(unit)
    @events.each do |event|
      if event.battler == unit
        event.highlight
        @highlighted_elements << event
      end
    end
  end

  def unhighlight_elements
    @highlighted_elements.each {|element| element.unhighlight}
    @highlighted_elements.clear
  end
  #---------------------------------------------------------------------------
  # Add an element to the list of known currently-moving elements.
  #---------------------------------------------------------------------------
  def anim_track_element(element)
    @animated_elements << element unless @animated_elements.include?(element)
  end
  #---------------------------------------------------------------------------
  # Remove an element from the list of known currently-moving elements.
  #---------------------------------------------------------------------------
  def anim_untrack_element(element)
    @animated_elements.delete(element)
  end

  def animating? ; return @animated_elements > 0 end

  def debug_print_schedule
    return @events.collect {|ev| "#{ev.time} #{ev.battler.name} #{ev.index}\n"}
  end
end # Rvkd_EventDisplay

#=============================================================================
# ■ Rvkd_EventDisplay_Element
#------------------------------------------------------------------------------
# A horizontally-tiling bar element in the event display list, showing the
# event's time, actor, and possibly the prepared action. Has several forms:
#  1. DECISION TURN: Short bar, indicating the battler's turn to input.
#  2. ACTION TURN: Long bar, indicating the battler and their prepared action.
#  3. BATTLE EVENT: Misc, indicates a timed environmental or other effect.
#=============================================================================
class Rvkd_EventDisplay_Element
  #---------------------------------------------------------------------------
  # * Public Instance Variables
  #---------------------------------------------------------------------------
  attr_accessor :index # The current index in the list for Y-axis positioning
  attr_accessor :event # The Rvkd_TimeSlotEvent tied to this display element.
  attr_reader :moving  # Whether this element is currently changing index.
  attr_reader :revealing # Whether this is currently sliding, being revealed.
  attr_reader :player_revealed # Whether the action can be seen by the player.
  attr_reader :time #debug
  attr_reader :battler #debug
  #---------------------------------------------------------------------------
  # * Object Initialization
  #---------------------------------------------------------------------------
  def initialize(event, viewport, index, tone)
    @event = event
    @battler = event.battler
    @action = event.type == :action ? event.action : nil
    @time = event.time
    @player_revealed = @event.revealed?
    # Initialize movement and position
    @cur_x = Phase::Config::Bar[:bar_init_x]
    @cur_y = calc_location_y(index)
    @goal_x = @cur_x
    @goal_y = @cur_y
    @shadow_goal_x = @cur_x + calc_offset_x
    @text_goal_alpha = @player_revealed ? Phase::Config::Bar[:item_name_a] : 0
    @moving = false
    @move_time = 0
    @revealing = false
    @reveal_time = 0
    @last_tone = :regular
    # Initialize background sprite
    @shadow_bar = Sprite.new(viewport)
    @shadow_bar.bitmap = Cache.grid_turn("event_bg_long")
    @shadow_bar.x = @cur_x + calc_offset_x
    @shadow_bar.y = @cur_y
    @shadow_bar.z = 2
    set_tone(tone)
    # Initialize the battler icon.
    face_name = @battler.battle_event_bar_face rescue ""
    @battler_face = Sprite.new(viewport)
    @battler_face.bitmap = Cache.grid_turn("turn_face" + face_name)
    @battler_face.x = @cur_x + Phase::Config::Bar[:face_x]
    @battler_face.y = @cur_y + Phase::Config::Bar[:face_y]
    @battler_face.z = 24
    # Initialize the time slot display and action icon.
    @time_icon_bar = Window_TurnBarTimeIcon.new(@cur_x, @cur_y)
    @time_icon_bar.draw_event_time(@time.truncate.to_s)
    @time_icon_bar.draw_event_icon(event.icon) if event.icon
    # Initialize the name bar for ability names.
    @text_bar = Window_TurnBarName.new(@cur_x, @cur_y)
    text_bar_name = @action.item.name if @action && @player_revealed
    text_bar_name = Phase::Config::PHASE_LABEL if @event.phase_shift?
    @text_bar.draw_event_name(text_bar_name) if text_bar_name
    # Set the item to slide in when created.
    change_index(index)
  end
  #---------------------------------------------------------------------------
  # Calculate a new position from an index and set a sliding movement goal.
  #---------------------------------------------------------------------------
  def change_index(index, time = 20)
    # Skip if not sliding in, and attempting to change to the same index.
    return if index == @index
    @index = index
    # Slides in from left to right when first created.
    @goal_x = Phase::Config::Bar[:x] unless @goal_x == Phase::Config::Bar[:x]
    @goal_y = calc_location_y(index)
    TurnManager.anim_track_element(self)
    @moving = true
    @move_time = time
  end

  #---------------------------------------------------------------------------
  # Lighten the item to indicate that it is being selected or targeted.
  #---------------------------------------------------------------------------
  def highlight
    @battler_face.tone = Phase::Config::Bar[:bar_tone][:target]
    #set_tone(:target, false)
  end
  def unhighlight
    return if @battler_face.disposed?
    @battler_face.tone = Phase::Config::Bar[:bar_tone][:regular]
    #set_tone(@last_tone, false)
  end
  #---------------------------------------------------------------------------
  # Reveal to the player the name of the unknown action item / ability.
  #---------------------------------------------------------------------------
  def reveal_action(time = 10)
    raise "trying to reveal nil action" unless @action
    raise "action has no item" unless @action.item
    raise "action has no name" unless @action.item.name
    @player_revealed = true
    @shadow_goal_x = @cur_x + calc_offset_x
    @text_goal_alpha = 255
    name = @action.item.name
    # Draw a transparent name.
    @text_bar.draw_event_name(name, Phase::Config::Bar[:item_name_a_init])
    @revealing = true
    @reveal_time = time
  end
  #---------------------------------------------------------------------------
  # Hide the action item from the player (No animation, just hides)
  #---------------------------------------------------------------------------
  def hide_action
    @player_revealed = false
    @shadow_bar.x = @cur_x + calc_offset_x
  end
  #---------------------------------------------------------------------------
  # Set the background bar tone.
  #---------------------------------------------------------------------------
  def set_tone(tone_symbol, remember_last_tone = true)
    return unless @shadow_bar
    @last_tone = tone_symbol if remember_last_tone
    @shadow_bar.tone = Phase::Config::Bar[:bar_tone][tone_symbol]
  end
  #---------------------------------------------------------------------------
  # Calculate the bar shadow's distance off the left edge to simulate length
  #---------------------------------------------------------------------------
  def calc_offset_x
    if @event.type == :action
      return @player_revealed ? 0 : Phase::Config::Bar[:hidden_bar_offset_x]
    elsif @event.type == :event && @event.phase_shift?
      return Phase::Config::Bar[:event_bar_offset_x]
    else # @event.type == :turn
      return Phase::Config::Bar[:short_bar_offset_x]
    end
  end
  #---------------------------------------------------------------------------
  # Calculate element position in the list based on index.
  #---------------------------------------------------------------------------
  def calc_location_y(index)
    loc = Phase::Config::Bar[:y] + index * Phase::Config::Bar[:bar_height]
    loc += Phase::Config::Bar[:top_offset] if index > 0
    return loc
  end
  #---------------------------------------------------------------------------
  # * Frame update
  #---------------------------------------------------------------------------
  def update
    update_move if @moving
    update_reveal if @revealing
  end

  # Update movement of the entire bar element.
  def update_move
    dist_x = @goal_x - @cur_x
    dist_y = @goal_y - @cur_y
    mov_x = dist_x / @move_time
    mov_y = dist_y / @move_time

    relocate_all_elements(mov_x, mov_y)
    @move_time -= 1
    finished = @move_time == 0 || (@cur_y == @goal_y && @cur_x == @goal_x)
    finish_moving if finished
  end

  # Updates the sliding background bar and reveals the action text.
  def update_reveal
    dist_x = @shadow_goal_x - @shadow_bar.x
    mov_x = dist_x / @reveal_time
    dist_alpha = @text_goal_alpha - @text_bar.contents_opacity
    mov_alpha = dist_alpha / @reveal_time

    @shadow_bar.x += mov_x
    @text_bar.contents_opacity += mov_alpha
    @reveal_time -= 1
    finish_revealing if @reveal_time == 0 || (@shadow_bar.x == @shadow_goal_x)
  end
  #---------------------------------------------------------------------------
  # Batch move the individual pieces of the bar element.
  #---------------------------------------------------------------------------
  def relocate_all_elements(dx, dy)
    @cur_x += dx
    @cur_y += dy

    @shadow_bar.x += dx
    @shadow_bar.y += dy
    @time_icon_bar.x += dx
    @time_icon_bar.y += dy
    @text_bar.x += dx
    @text_bar.y += dy
    if @battler_face
      @battler_face.x += dx
      @battler_face.y += dy
    end
  end
  #---------------------------------------------------------------------------
  # Process entire movement completion
  #---------------------------------------------------------------------------
  def finish_moving
    TurnManager.anim_untrack_element(self) unless @revealing
    @moving = false
    @move_time = 0
    msgbox_p("Movement skipped") if (@cur_y - @goal_y).abs > 10
    @cur_y = @goal_y
  end
  #---------------------------------------------------------------------------
  # Process shadow / opacity revealing completion
  #---------------------------------------------------------------------------
  def finish_revealing
    TurnManager.anim_untrack_element(self) unless @moving
    @revealing = false
    @reveal_time = 0
    @shadow_bar.x = @shadow_goal_x
  end
  #---------------------------------------------------------------------------
  # * Free
  #---------------------------------------------------------------------------
  def dispose
    @shadow_bar.dispose
    @time_icon_bar.dispose
    @text_bar.dispose
    @battler_face.dispose
  end
end # Rvkd_EventDisplay_Element

#=============================================================================
# ■ Window_TurnBarTimeIcon
#=============================================================================
class Window_TurnBarTimeIcon < Window_Base
  #---------------------------------------------------------------------------
  # * Object Initialization
  #---------------------------------------------------------------------------
  def initialize(x, y)
    super(x,y,Phase::Config::Bar[:bar_width],Phase::Config::Bar[:bar_height])
    self.x = x
    self.y = y
    self.z = 40
    self.opacity = 0
  end
  #---------------------------------------------------------------------------
  # Draw time slot on the left edge.
  #---------------------------------------------------------------------------
  def draw_event_time(text)
    width = Phase::Config::Bar[:time_width]
    height = Phase::Config::Bar[:bar_height]
    contents.font.size = Phase::Config::Bar[:time_font_size]
    draw_text(Rect.new(0, 0, width, height), text, 1)
  end
  #---------------------------------------------------------------------------
  # Draw the event action icon on the right.
  #---------------------------------------------------------------------------
  def draw_event_icon(icon_index)
    icon_x = Phase::Config::Bar[:item_icon_x]
    icon_y = Phase::Config::Bar[:item_icon_y]
    draw_icon(icon_index, icon_x, icon_y)
  end
  #---------------------------------------------------------------------------
  # Setup the rects used to draw the time and event label.
  #---------------------------------------------------------------------------
  def setup_time_rect
    width = Phase::Config::Bar[:time_width]
    height = Phase::Config::Bar[:bar_height]
    return
  end

  def standard_padding ; 1 end
end # Window_TurnBarTimeIcon

#=============================================================================
# ■ Window_TurnBarName
#=============================================================================
class Window_TurnBarName < Window_Base
  #---------------------------------------------------------------------------
  # * Object Initialization
  #---------------------------------------------------------------------------
  def initialize(x, y)
    super(x,y,Phase::Config::Bar[:bar_width],Phase::Config::Bar[:bar_height])
    self.x = x
    self.y = y
    self.z = 32
    self.opacity = 0
  end
  #---------------------------------------------------------------------------
  # Draw the name of the ability on the right.
  #---------------------------------------------------------------------------
  def draw_event_name(name, opacity = Phase::Config::Bar[:item_name_a])
    width = Phase::Config::Bar[:item_name_width]
    x = Phase::Config::Bar[:item_name_x]
    y = Phase::Config::Bar[:item_name_y]
    height = Phase::Config::Bar[:bar_height]
    contents.font.size = Phase::Config::Bar[:item_name_font_size]
    draw_text(Rect.new(x, y, width, height), name, 0)
    self.contents_opacity = opacity
  end

  def standard_padding ; 1 end
end # Window_TurnBarName

#==============================================================================
#
# ▼ End of File
#
#==============================================================================
