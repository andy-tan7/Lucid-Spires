#==============================================================================
# Grid Shift Phase Turn Battle System - Turn Bar
#------------------------------------------------------------------------------
#  This script creates and maintains the visual display for turns in battle.
#==============================================================================
# ■ PhaseTurn
#==============================================================================
module PhaseTurn

  #---------------------------------------------------------------------------
  # * Initialize battle event display.
  #---------------------------------------------------------------------------
  def self.create_event_display(viewport)
    @event_display = Rvkd_EventDisplay.new(viewport)
    return @event_display
  end

  def self.start_new_event_display
    @event_display.reset_display
    @schedule.each_with_index do |event, index|
      case event.type
      when :event  ; add_display_global_event(index, event)
      when :turn   ; add_display_unit_event(index, event)
      when :action ; add_display_unit_event(index, event)
      end
    end
  end

  def self.update_event_display
    @event_display.update_display
  end

  def self.refresh_event_display_list
    @event_display.refresh_list(@current_time)
  end
  #---------------------------------------------------------------------------
  # Traverse the event display to update event action visibility.
  #---------------------------------------------------------------------------
  def self.refresh_revealed_events
    @event_display.refresh_revealed_events
  end
  #---------------------------------------------------------------------------
  # * Add events
  #---------------------------------------------------------------------------
  def self.add_display_global_event(index, event)
    raise "not implemented: add_event"
  end

  def self.add_display_unit_event(index, event, tone = :regular)
    @event_display.create_unit_event(event, index, tone)
  end

  def self.remove_display_event(rem_event)
    @event_display.remove_display_element(rem_event)
  end

  def self.remove_multiple_events(rem_events)
    @event_display.remove_multiple_elements(rem_events)
  end
  #---------------------------------------------------------------------------
  # Process completion of the current displayed event.
  #---------------------------------------------------------------------------
  def self.finish_current_event
    remove_display_event(@current_event)
  end
  #---------------------------------------------------------------------------
  # Keep track of known moving display elements.
  #---------------------------------------------------------------------------
  def self.anim_track_element(element)
    @event_display.anim_track_element(element)
  end

  def self.anim_untrack_element(element)
    @event_display.anim_untrack_element(element)
  end
  #---------------------------------------------------------------------------
  # * Demo selected actions.
  #---------------------------------------------------------------------------
  def self.indicate_player_selected_event(event)
    ins_at = event.time == @current_time ? 1 : nil
    ins_at ||= get_insertion_index(event.time, @event_display.get_times_array)
    @temp_display_action = add_display_unit_event(ins_at, event, :gold)
  end

  # Demo the player's next turn if they confirm the indicated action.
  def self.indicate_player_selected_next_turn(event)
    ins_at = event.time == @current_time ? 1 : nil
    ins_at ||= get_insertion_index(event.time, @event_display.get_times_array)
    @temp_display_next_turn = add_display_unit_event(ins_at, event, :gold)
  end

  # Remove any temporary demo actions.
  def self.cancel_indicated_events
    remove_display_event(@temp_display_action.event)
    remove_display_event(@temp_display_next_turn.event)
    @temp_display_action = nil
    @temp_display_next_turn = nil
  end

  def self.get_temp_events
    [@temp_display_action, @temp_display_next_turn]
  end
  #---------------------------------------------------------------------------
  # Change the background shadow tones for the temp events.
  #---------------------------------------------------------------------------
  def self.set_temp_tone(tone_symbol = :regular)
    get_temp_events.each {|temp| temp.set_tone(tone_symbol) }
  end
  #---------------------------------------------------------------------------
  # Retrieve the corresponding display element for an event.
  #---------------------------------------------------------------------------
  def self.get_display_element_from_event(event)
    return @event_display.get_display_element_from_event(event)
  end
end # module PhaseTurn

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
  end
  #---------------------------------------------------------------------------
  # Create a visual display bar for a unit's turn or action event.
  #---------------------------------------------------------------------------
  def create_unit_event(event, index, tone)
    index ||= PhaseTurn.get_insertion_index(event.time, get_times_array)
    element = Rvkd_EventDisplay_Element.new(event, @viewport, index, tone)
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
    raise "attempt to delete element not in the event list." unless index

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
    @cur_x = PhaseTurn::Bar[:bar_init_x]
    @cur_y = calc_location_y(index)
    @goal_x = @cur_x
    @goal_y = @cur_y
    @shadow_goal_x = @cur_x + calc_offset_x
    @text_goal_alpha = @player_revealed ? PhaseTurn::Bar[:item_name_alpha] : 0
    @moving = false
    @move_time = 0
    @revealing = false
    @reveal_time = 0
    # Initialize background sprite
    @shadow_bar = Sprite.new(viewport)
    @shadow_bar.bitmap = Cache.grid_turn("event_bg_long")
    @shadow_bar.x = @cur_x + calc_offset_x
    @shadow_bar.y = @cur_y
    @shadow_bar.z = 2
    set_tone(tone)
    # Initialize the battler icon.
    face_name = @battler.battle_event_bar_face
    @battler_face = Sprite.new(viewport)
    @battler_face.bitmap = Cache.grid_turn("turn_face" + face_name)
    @battler_face.x = @cur_x + PhaseTurn::Bar[:face_x]
    @battler_face.y = @cur_y + PhaseTurn::Bar[:face_y]
    @battler_face.z = 24
    # Initialize the time slot display and action icon.
    @time_icon_bar = Window_TurnBarTimeIcon.new(@cur_x, @cur_y)
    @time_icon_bar.draw_event_time(@time.truncate.to_s)
    @time_icon_bar.draw_event_icon(event.icon) if event.icon
    # Initialize the name bar for ability names.
    @text_bar = Window_TurnBarName.new(@cur_x, @cur_y)
    @text_bar.draw_event_name(@action.item.name) if @action && @player_revealed
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
    @goal_x = PhaseTurn::Bar[:x] unless @goal_x == PhaseTurn::Bar[:x]
    @goal_y = calc_location_y(index)
    PhaseTurn.anim_track_element(self)
    @moving = true
    @move_time = time
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
    @text_bar.draw_event_name(name, PhaseTurn::Bar[:item_name_alpha_init])
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
  def set_tone(tone_symbol)
    return unless @shadow_bar
    @shadow_bar.tone = PhaseTurn::Bar[:bar_tone][tone_symbol]
  end
  #---------------------------------------------------------------------------
  # Calculate the bar shadow's distance off the left edge to simulate length
  #---------------------------------------------------------------------------
  def calc_offset_x
    if @event.type == :action
      return @player_revealed ? 0 : PhaseTurn::Bar[:unrevealed_bar_offset_x]
    elsif @event.type == :turn || @event.type == :event
      return PhaseTurn::Bar[:short_bar_offset_x]
    end
  end
  #---------------------------------------------------------------------------
  # Calculate element position in the list based on index.
  #---------------------------------------------------------------------------
  def calc_location_y(index)
    loc = PhaseTurn::Bar[:y] + index * PhaseTurn::Bar[:bar_height]
    loc += PhaseTurn::Bar[:top_offset] if index > 0
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
    @battler_face.x += dx
    @battler_face.y += dy
  end
  #---------------------------------------------------------------------------
  # Process entire movement completion
  #---------------------------------------------------------------------------
  def finish_moving
    PhaseTurn.anim_untrack_element(self) unless @revealing
    @moving = false
    @move_time = 0
    msgbox_p("Movement skipped") if (@cur_y - @goal_y).abs > 10
    @cur_y = @goal_y
  end
  #---------------------------------------------------------------------------
  # Process shadow / opacity revealing completion
  #---------------------------------------------------------------------------
  def finish_revealing
    PhaseTurn.anim_untrack_element(self) unless @moving
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
    super(x, y, PhaseTurn::Bar[:bar_width], PhaseTurn::Bar[:bar_height])
    self.x = x
    self.y = y
    self.z = 40
    self.opacity = 0
  end
  #---------------------------------------------------------------------------
  # Draw time slot on the left edge.
  #---------------------------------------------------------------------------
  def draw_event_time(text)
    width = PhaseTurn::Bar[:time_width]
    height = PhaseTurn::Bar[:bar_height]
    contents.font.size = PhaseTurn::Bar[:time_font_size]
    draw_text(Rect.new(0, 0, width, height), text, 1)
  end
  #---------------------------------------------------------------------------
  # Draw the event action icon on the right.
  #---------------------------------------------------------------------------
  def draw_event_icon(icon_index)
    icon_x = PhaseTurn::Bar[:item_icon_x]
    icon_y = PhaseTurn::Bar[:item_icon_y]
    draw_icon(icon_index, icon_x, icon_y)
  end
  #---------------------------------------------------------------------------
  # Setup the rects used to draw the time and event label.
  #---------------------------------------------------------------------------
  def setup_time_rect
    width = PhaseTurn::Bar[:time_width]
    height = PhaseTurn::Bar[:bar_height]
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
    super(x, y, PhaseTurn::Bar[:bar_width], PhaseTurn::Bar[:bar_height])
    self.x = x
    self.y = y
    self.z = 32
    self.opacity = 0
  end
  #---------------------------------------------------------------------------
  # Draw the name of the ability on the right.
  #---------------------------------------------------------------------------
  def draw_event_name(name, opacity = PhaseTurn::Bar[:item_name_alpha])
    width = PhaseTurn::Bar[:item_name_width]
    x = PhaseTurn::Bar[:item_name_x]
    y = PhaseTurn::Bar[:item_name_y]
    height = PhaseTurn::Bar[:bar_height]
    contents.font.size = PhaseTurn::Bar[:item_name_font_size]
    draw_text(Rect.new(x, y, width, height), name, 0)
    self.contents_opacity = opacity
  end

  def standard_padding ; 1 end
end # Window_TurnBarName

#=============================================================================
# ■ Scene_Battle
#=============================================================================
class Scene_Battle
  alias rvkd_phaseturn_bar_scb_create_spriteset create_spriteset
  def create_spriteset
    rvkd_phaseturn_bar_scb_create_spriteset
    @event_display = @spriteset.create_event_display
  end

  alias rvkd_phaseturn_bar_scb_update_basic update_basic
  def update_basic
    rvkd_phaseturn_bar_scb_update_basic
    PhaseTurn.update_event_display
  end
end # Scene_Battle

#==============================================================================
#
# ▼ End of File
#
#==============================================================================
