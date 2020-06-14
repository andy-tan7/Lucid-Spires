#==============================================================================
# Grid Shift Phase Turn Battle System - Turn Bar
#------------------------------------------------------------------------------
#  This script creates and maintains the visual display for turns in battle.
#==============================================================================

module PhaseTurn

  Bar = {
    :x => 0,
    :y => 4,
    :bar_init_x => -250,

    :time_width => 36,
    :time_font_size => 18,

    :face_x => 36,
    :face_y => -1,

    :item_icon_x => 66,
    :item_icon_y => 0,

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
    }
  }

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

  def self.finish_current_event
    remove_display_event(@current_event)
  end

  # Display movement
  def self.anim_track_moving_element(element)
    @event_display.anim_track_moving_element(element)
  end

  def self.anim_remove_moving_element(element)
    @event_display.anim_remove_moving_element(element)
  end

  # Given a timeslot event, add a temporary displayed event to the list.
  def self.indicate_player_selected_event(event)
    ins_at = event.time == @current_time ? 1 : nil
    ins_at ||= get_insertion_index(event.time, @event_display.get_times_array)
    @temp_display_action = add_display_unit_event(ins_at, event, :gold)
  end

  def self.indicate_player_selected_next_turn(event)
    ins_at = event.time == @current_time ? 1 : nil
    ins_at ||= get_insertion_index(event.time, @event_display.get_times_array)
    @temp_display_next_turn = add_display_unit_event(ins_at, event, :gold)
  end

  def self.cancel_indicated_events
    remove_display_event(@temp_display_action.event)
    remove_display_event(@temp_display_next_turn.event)
    @temp_display_action = nil
    @temp_display_next_turn = nil
  end

  def self.get_temp_events
    [@temp_display_action, @temp_display_next_turn]
  end

  def self.set_temp_tone(tone_symbol = :regular)
    get_temp_events.each {|temp| temp.set_tone(tone_symbol) }
  end

end

#=============================================================================
# ■ Rvkd_EventDisplay
#-----------------------------------------------------------------------------
# The visual list of event elements, ordered by their time of exeucution.
# This class handles creation and deletion of all event elements.
#=============================================================================
class Rvkd_EventDisplay

  attr_reader :moving_elements

  def initialize(viewport)
    @viewport = viewport
    reset_display
  end

  # Reset the event display, disposing all events.
  def reset_display
    dispose_events if @events
    @events = []
    @moving_elements = []
  end

  # Create a visual display bar for a unit's turn or action event.
  def create_unit_event(event, index, tone)
    index ||= PhaseTurn.get_insertion_index(event.time, get_times_array)
    element = Rvkd_EventDisplay_Element.new(event, @viewport, index, tone)
    add_display_element(element)
  end

  # Add a turn display element to the event list.
  def add_display_element(element)
    element.index ||= @events.length
    @events.insert(element.index, element)
    @events.each_with_index {|ev, i| ev.change_index(i) }
    return element
  end

  # Remove a single element from the element list.
  def remove_display_element(element)
    index = @events.find_index {|ev| ev.event == element }
    raise "attempt to delete element not in the event list." unless index

    @moving_elements.delete(@events[index])
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
      @moving_elements.delete(elem)
      elem.dispose
      @events.delete(elem)
    end
    @events.each_with_index {|ev, i| ev.change_index(i) if ev.index != i}
  end

  # Recursively dispose of all elements in the display.
  def dispose_events ; @events.each {|event| event.dispose } end

  # Update any moving elements (slide animation).
  def update_display
    return unless @moving_elements.any?
    @moving_elements.reverse_each {|element| element.update }
  end

  # Get the array of event times (automatically sorted in increasing order).
  def get_times_array
    return @events.collect {|element| element.event.time }
  end

  # Add an element to the list of known currently-moving elements.
  def anim_track_moving_element(element)
    @moving_elements.push(element) unless @moving_elements.include?(element)
  end

  # Remove an element from the list of known currently-moving elements.
  def anim_remove_moving_element(element)
    @moving_elements.delete(element)
  end

  def moving? ; return @moving_elements > 0 end

  def debug_print_schedule
    return @events.collect {|ev| "#{ev.time} #{ev.battler.name} #{ev.index}\n"}
  end

end

#=============================================================================
# ■ Rvkd_EventDisplay_Element
#-----------------------------------------------------------------------------
# A horizontally-tiling bar element in the event display list, showing the
# event's time, actor, and possibly the prepared action. Has several forms:
#  1. DECISION TURN: Short bar, indicating the battler's turn to input.
#  2. ACTION TURN: Long bar, indicating the battler and their prepared action.
#  3. BATTLE EVENT: Misc, indicates a timed environmental or other effect.
#=============================================================================
class Rvkd_EventDisplay_Element

  attr_accessor :index # The current index in the list for Y-axis positioning
  attr_accessor :event # The Rvkd_TimeSlotEvent tied to this display element.
  attr_reader :moving  # Whether this element is currently changing index.
  attr_reader :revealing
  attr_reader :time #debug
  attr_reader :battler #debug

  def initialize(event, viewport, index, tone)
    @event = event
    @battler = event.battler
    @action = event.type == :action ? event.action : nil
    @time = event.time

    # Initialize movement and position
    @cur_x = PhaseTurn::Bar[:bar_init_x]
    @cur_y = calc_location_y(index)
    @goal_x = @cur_x
    @goal_y = @cur_y
    @moving = false
    @move_time = 0

    # Initialize background sprite
    @shadow_bar = Sprite.new(viewport)
    @shadow_bar.bitmap = Cache.grid_turn("event_bg" +(@action ? "_long" : ""))
    @shadow_bar.x = @cur_x
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

    # Initialize any text to be drawn on the bar.
    @text_bar = Window_TurnBarText.new(@cur_x, @cur_y)
    @text_bar.draw_event_time(@time.truncate.to_s)
    if event.type == :action
      i = @action.item
      @text_bar.draw_event_ability(i.icon_index, "#{@battler.name} #{i.name}")
    end

    # Set the item to slide in when created.
    change_index(index)
  end

  def change_index(index, time = 20)
    # Skip if not sliding in, and attempting to change to the same index.
    return if index == @index

    @index = index
    @goal_x = PhaseTurn::Bar[:x] unless @goal_x == PhaseTurn::Bar[:x]
    @goal_y = calc_location_y(index)
    PhaseTurn.anim_track_moving_element(self)
    @moving = true
    @move_time = time
  end

  def calc_location_y(index)
    loc = PhaseTurn::Bar[:y] + index * PhaseTurn::Bar[:bar_height]
    loc += PhaseTurn::Bar[:top_offset] if index > 0
    return loc
  end

  def update
    return unless @moving

    dist_x = @goal_x - @cur_x
    dist_y = @goal_y - @cur_y

    mov_x = dist_x / @move_time
    mov_y = dist_y / @move_time

    relocate_elements(mov_x, mov_y)
    @move_time -= 1

    if @move_time == 0 || (@cur_y == @goal_y && @cur_x == @goal_x)
      finish_moving
    end
  end

  def relocate_elements(dx, dy)
    @cur_x += dx
    @cur_y += dy

    @shadow_bar.x += dx
    @shadow_bar.y += dy
    @text_bar.x += dx
    @text_bar.y += dy
    @battler_face.x += dx
    @battler_face.y += dy
  end

  def finish_moving
    PhaseTurn.anim_remove_moving_element(self)
    @moving = false
    @move_time = 0
    msgbox_p("Movement skipped") if (@cur_y - @goal_y).abs > 10
    @cur_y = @goal_y
  end

  def set_tone(tone_symbol)
    return unless @shadow_bar
    @shadow_bar.tone = PhaseTurn::Bar[:bar_tone][tone_symbol]
  end

  def dispose
    @shadow_bar.dispose
    @text_bar.dispose
    @battler_face.dispose
  end

end

class Window_TurnBarText < Window_Base
  def initialize(x, y)
    super(x, y, PhaseTurn::Bar[:bar_width], PhaseTurn::Bar[:bar_height])
    self.x = x
    self.y = y
    self.z = 32
    self.opacity = 0
  end

  def draw_event_time(text)
    width = PhaseTurn::Bar[:time_width]
    height = PhaseTurn::Bar[:bar_height]
    contents.font.size = PhaseTurn::Bar[:time_font_size]
    draw_text(Rect.new(0, 0, width, height), text, 1)
  end

  def draw_event_ability(icon_index, name)
    width = PhaseTurn::Bar[:item_name_width]
    x = PhaseTurn::Bar[:item_name_x]
    y = PhaseTurn::Bar[:item_name_y]
    height = PhaseTurn::Bar[:bar_height]
    icon_x = PhaseTurn::Bar[:item_icon_x]
    icon_y = PhaseTurn::Bar[:item_icon_y]
    contents.font.size = PhaseTurn::Bar[:item_name_font_size]
    draw_icon(icon_index, icon_x, icon_y)
    draw_text(Rect.new(x, y, width, height), name, 0)
  end

  def standard_padding ; 1 end
end

class Spriteset_Battle

  def create_event_display
    @event_display = PhaseTurn.create_event_display(@viewport1)
    return @event_display
  end

  alias rvkd_phaseturn_bar_spb_dispose dispose
  def dispose
    rvkd_phaseturn_bar_spb_dispose
    dispose_turn_display
  end

  def dispose_turn_display
    @event_display.dispose_events
  end

end

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

end

class Game_Battler
  def battle_event_bar_face
    return "_" + name
  end
end

class Game_Enemy
  def battle_event_bar_face
    return "_" + $1.to_s if enemy.note =~ /<event_face[\s_]*:\s*(\w+)>/i
    return ""
  end
end
