#==============================================================================
# Grid Shift Phase Turn Battle System - Turn Bar
#------------------------------------------------------------------------------
#  This script creates and maintains the visual display for turns in battle.
#==============================================================================

module PhaseTurn

  Bar = {
    :x => 0,
    :y => 4,

    :bar_height => 25,
  }

  def self.create_turn_display(viewport)
    @event_display = Rvkd_EventDisplay.new(viewport)
    return @event_display
  end

  def self.start_new_turn_display
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

  def self.add_display_unit_event(index, event)
    @event_display.create_unit_event(event, index)
  end

  def self.remove_display_event(event)
    @event_display.remove_display_element(event)
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

end

class Rvkd_EventDisplay

  attr_reader :moving_elements

  def initialize(viewport)
    @viewport = viewport
    reset_display
  end

  def reset_display
    dispose_events if @events
    @events = []
    @moving_elements = []
  end

  # Create a bar for a unit's turn or action event.
  def create_unit_event(event, index = nil)
    # Create the unit icon and the time slot text.
    bar = Rvkd_TurnBar.new(event, @viewport)
    add_display_element(bar, index)
  end

  # Add a turn display element to the event list.
  def add_display_element(element, index = nil)
    index ||= @events.length
    shift_indices = index...(@events.length - 1)

    # Shift backward the Y position of the elements behind the added event.
    @events[shift_indices].each {|event| event.change_index(event.index + 1) }
    @events.insert(index, element)

    element.change_index(index)
  end

  def remove_display_element(event)
    # msgbox_p("removing: #{event.time} - #{event.type}, - #{event.battler.name}")
    # msgbox_p(@events.collect {|ev| "#{ev.time}, #{ev.battler.name}" })

    index = @events.find_index {|ev| ev.event == event }

    raise "attempt to delete element not in the event list." unless index
    shift_indices = (index + 1)...@events.length
    #msgbox_p("Removing index #{index}. Shifting #{shift_indices.to_a}.")

    # Shift forward the Y position of elements behind the removed event.
    @events[shift_indices].each {|event| event.change_index(event.index - 1) }

    @moving_elements -= [@events[index]]
    @events[index].dispose
    @events.delete_at(index)
  end

  def dispose_events ; @events.each {|event| event.dispose } end

  def update_display
    # Update any moving elements (slide).
    if @moving_elements.any?
      @moving_elements.each {|element| element.update }
    end
  end

  def refresh_event_display_list(current_time)

  end

  def anim_track_moving_element(element)
    @moving_elements.push(element) unless @moving_elements.include?(element)
  end

  def anim_remove_moving_element(element)
    @moving_elements.delete(element)
  end

  def moving?
    return @moving_elements > 0
  end

  def debug_print_schedule
    return @events.collect {|ev| "#{ev.time} #{ev.battler.name} #{ev.index}\n"}
  end

end

class Rvkd_TurnBar

  attr_reader :index
  attr_reader :moving
  attr_reader :event
  attr_reader :time #debug
  attr_reader :battler #debug

  def initialize(event, viewport)
    @event = event
    @battler = event.battler
    @action = event.type == :action ? event.action : nil
    @time = event.time
    @index = nil

    @cur_x = PhaseTurn::Bar[:x]
    @cur_y = PhaseTurn::Bar[:y]
    @goal_x = @cur_x
    @goal_y = @cur_y
    @moving = false
    @move_time = 0

    @shadow_bar = Sprite.new(viewport)
    @shadow_bar.bitmap = Cache.grid_turn("event_bg_long")
    @shadow_bar.x = @cur_x
    @shadow_bar.y = @cur_y
    @shadow_bar.z = 2

    @text_window = Window_TurnBarText.new(@cur_x, @cur_y)
    @text_window.draw_event_time(@time.truncate.to_s)
    if event.type == :action
      ability = @action.item
      @text_window.draw_event_ability(ability.icon_index, "#{@battler.name} #{ability.name}")
    end

    # if action
    #   # Create the icon and text, and use the extended shadow bar.
    # end
  end

  def change_index(index, time = 20)
    @index = index
    @goal_y = PhaseTurn::Bar[:y] + @index * PhaseTurn::Bar[:bar_height]
    PhaseTurn.anim_track_moving_element(self)
    @moving = true
    @move_time = time
  end

  def update
    return unless @moving

    dist_y = @goal_y - @cur_y
    mov_y = dist_y / @move_time

    relocate_elements(0, mov_y)
    @move_time -= 1

    if @move_time == 0 || @cur_y == @goal_y
      finish_moving
    end
  end

  def relocate_elements(dx, dy)
    @cur_x += dx
    @cur_y += dy

    @shadow_bar.x += dx
    @shadow_bar.y += dy
    @text_window.x += dx
    @text_window.y += dy
  end

  def finish_moving
    PhaseTurn.anim_remove_moving_element(self)
    @moving = false
    @move_time = 0
    msgbox_p("Movement skipped") if (@cur_y - @goal_y).abs > 10
    @cur_y = @goal_y
  end

  def dispose
    @shadow_bar.dispose
    @text_window.dispose
  end

end

class Window_TurnBarText < Window_Base
  def initialize(x, y)
    super(x,y,300,25)
    self.x = x
    self.y = y
    self.z = 32
    self.opacity = 25 #0
  end

  def draw_event_time(text)
    time_rect = Rect.new(0, 0, 36, 25)
    contents.font.size = 16
    draw_text(time_rect, text, 1)
  end

  def draw_event_ability(icon_index, name)
    ability_rect = Rect.new(144, 0, 156, 25)
    contents.font.size = 18
    draw_icon(icon_index, 120, 0)
    draw_text(ability_rect, name, 0)
  end

  def standard_padding ; 1 end
end

class Spriteset_Battle

  def create_turn_display
    @event_display = PhaseTurn.create_turn_display(@viewport1)
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
    @event_display = @spriteset.create_turn_display
  end

  alias rvkd_phaseturn_bar_scb_update_basic update_basic
  def update_basic
    rvkd_phaseturn_bar_scb_update_basic
    PhaseTurn.update_event_display
  end

end
