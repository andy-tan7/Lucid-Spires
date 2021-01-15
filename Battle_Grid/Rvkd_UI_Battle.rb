#==============================================================================
# Rvkd Battle UI
#------------------------------------------------------------------------------
#  This script defines the layout of battle UI elements.
#==============================================================================

module Cache
  def self.battle_ui(filename)
    load_bitmap("Graphics/BattleUI/", filename)
  end
end

module Revoked
  module BattleUI

    Description = {
      :attack => "Strike with a basic weapon attack.",
      :guard  => "Enter a defensive pose.",
      :item   => "Use a consumable item."
    }

    SType_Desc = {
      1 => "Perform a special ability.",
      2 => "Cast a spell."
    }

    FONT_LARGE = 72
    FONT_NAME = "EB Garamond 08 Standard Digit"
    FONT_WHITE = Color.new(255,255,255,255)
    SPLASH_OPACITY = 20

    BUTTON_WIDTH = 58
    COMMAND_PADDING = 4
    COMMAND_SPACING = 4
    COMMAND_Y = 474

    SPLASH_WIDTH = 360

  end
end

#==============================================================================
# ■ Scene_Battle
#==============================================================================
class Scene_Battle

  # Override
  def create_info_viewport
    @info_viewport = Viewport.new
    @info_viewport.rect.y = 0
    @info_viewport.rect.height = Graphics.height
    @info_viewport.z = 100
    @info_viewport.ox = 0
    @status_window.viewport = @info_viewport
    @status_window.x = (Graphics.width - @status_window.width) / 2
    @status_window.y = 376
  end

  # Override
  def create_actor_command_window
    @actor_command_window = Window_ActorCommand.new
    @actor_command_window.opacity = 0
    @actor_command_window.arrows_visible = false
    @actor_command_window.viewport = @info_viewport
    @actor_command_window.set_handler(:attack, method(:command_attack))
    @actor_command_window.set_handler(:skill,  method(:command_skill))
    @actor_command_window.set_handler(:guard,  method(:command_guard))
    @actor_command_window.set_handler(:item,   method(:command_item))
    @actor_command_window.set_handler(:cancel, method(:prior_command))
    @actor_command_window.refresh_position
  end

  # Override / delete
  def update_info_viewport
  end

  def create_battle_ui
    @battle_ui = BattleUI_Bar.new(@info_viewport, @actor_command_window)
  end

  alias rvkd_battleui_scb_create_all_windows create_all_windows
  def create_all_windows
    rvkd_battleui_scb_create_all_windows
    create_battle_ui
    @item_window.arrows_visible = false
  end

  alias rvkd_battleui_scb_update_basic update_basic
  def update_basic
    rvkd_battleui_scb_update_basic
    @battle_ui.update if @battle_ui.needs_update?
  end

  alias rvkd_battleui_scb_start_actor_cmd_select start_actor_command_selection
  def start_actor_command_selection
    rvkd_battleui_scb_start_actor_cmd_select
    @battle_ui.show
  end

  alias rvkd_battleui_scb_start_next_action start_next_action
  def start_next_action(event)
    rvkd_battleui_scb_start_next_action(event)
    @battle_ui.hide
  end

end

#==============================================================================
# ■ Window_BattleStatus
#==============================================================================
class Window_BattleStatus < Window_Selectable

  def window_width ; Graphics.width / 2 ; end
  def window_height ; 96 ; end

end

#==============================================================================
# ■ Window_ActorCommand
#-----------------------------------------------------------------------------
# Override Window_ActorCommand window appearance and behaviour
#==============================================================================
class Window_ActorCommand < Window_Command

  def row_max ; 1 end
  def col_max ; 10 end
  def line_height ; Revoked::BattleUI::BUTTON_WIDTH end
  def item_width ; Revoked::BattleUI::BUTTON_WIDTH end
  def spacing ; Revoked::BattleUI::COMMAND_SPACING end
  def standard_padding ; Revoked::BattleUI::COMMAND_PADDING end

  def window_width
    return 2 * standard_padding + @list.size * (item_width + spacing) - spacing
  end

  def window_height
    return 2 * standard_padding + line_height
  end

  def refresh_position
    self.x = Graphics.width - window_width
    self.y = Graphics.height - window_height
  end

  def set_command_help(command_help_window)
    @help_window = command_help_window
  end

  def set_splash_window(splash_window)
    @splash_window = splash_window
  end

  alias rvkd_battleui_actorcommand_clear_command_list clear_command_list
  def clear_command_list
    rvkd_battleui_actorcommand_clear_command_list

    @command_buttons ||= []
    @command_buttons.each {|button| button.dispose}
    @command_buttons.clear
  end

  alias rvkd_battleui_actorcommand_make_command_list make_command_list
  def make_command_list
    return unless @actor
    rvkd_battleui_actorcommand_make_command_list
    reposition_command_buttons
  end

  def reposition_command_buttons
    return if @list.empty?

    self.width = window_width
    self.x = Graphics.width - self.width

    return unless @command_buttons && !@command_buttons.empty?
    num_buttons = @command_buttons.size
    @command_buttons.each_with_index do |button, i|
      button.set_position(i, num_buttons)
    end
  end

  # Override
  def add_command_desc(n, s, d, enabled = true, ext = nil)
    @list.push({:name=>n, :symbol=>s, :desc=>d, :enabled=>enabled, :ext=>ext})
  end

  # Override adding commands.
  def add_attack_command
    symbol = :attack
    desc = Revoked::BattleUI::Description[symbol]
    add_command_desc(Vocab::attack, symbol, desc, @actor.attack_usable?)
    @command_buttons.push(BattleUI_Button.new(viewport, symbol))
  end

  # Override
  def add_skill_commands
    @actor.added_skill_types.sort.each do |stype_id|
      name = $data_system.skill_types[stype_id]
      desc = Revoked::BattleUI::SType_Desc[stype_id]
      add_command_desc(name, :skill, desc, true, stype_id)
      @command_buttons.push(BattleUI_Button.new(viewport, name))
    end
  end

  # Override
  def add_guard_command
    symbol = :guard
    desc = Revoked::BattleUI::Description[symbol]
    add_command_desc(Vocab::guard, symbol, desc, @actor.guard_usable?)
    @command_buttons.push(BattleUI_Button.new(viewport, symbol))
  end

  def add_item_command
    symbol = :item
    desc = Revoked::BattleUI::Description[symbol]
    add_command_desc(Vocab::item, symbol, desc)
    @command_buttons.push(BattleUI_Button.new(viewport, symbol))
  end

  # Override
  def index=(index)
    last_index = @index
    @index = index
    update_cursor

    if @help_window && current_data && (@index != last_index || last_index.nil?)
      p(current_data[:desc])
      @help_window.set_desc(current_data[:desc].dup)
      @splash_window.set_splash(current_data[:name])
      @command_buttons.each_with_index do |button, i|
        @index == i ? button.select_button : button.unselect_button
      end
    end
  end

  alias rvkd_battleui_actorcommand_show show
  def show
    rvkd_battleui_actorcommand_show
    @help_window.show
    @splash_window.show
  end

  alias rvkd_battleui_actorcommand_hide hide
  def hide
    rvkd_battleui_actorcommand_hide
    @help_window.hide
    @splash_window.hide
    @command_buttons.each {|button| button.dispose } if @command_buttons
  end

  # Override - don't draw the text for the command name.
  def draw_item(index)
    change_color(normal_color, command_enabled?(index))
  end

  def pending_color
    return Color.new(255,255,255,255)
  end

  # Override
  def update_help
  end

end

#==============================================================================
# ■ BattleUI_Bar
#-----------------------------------------------------------------------------
# Define the GUI bottom bar with actor command buttons and descriptions.
#==============================================================================
class BattleUI_Bar

  attr_reader :command_help_window

  def initialize(viewport, actor_command_window)
    @actor_command_window = actor_command_window

    help_width = Graphics.width - actor_command_window.width
    @command_help_window = Window_BattleUI_Help.new(help_width)
    @command_splash_window = Window_BattleUI_Splash.new(help_width)

    @actor_command_window.set_command_help(@command_help_window)
    @actor_command_window.set_splash_window(@command_splash_window)

    @background_bar = Sprite.new(viewport)
    @background_bar.bitmap = Cache.battle_ui("command_background")
    @background_bar.x = -10
    @background_bar.y = Graphics.height - 96
  end

  def show
    @actor_command_window.show
    @command_help_window.show
    @command_splash_window.show
    #@background_bar.opacity = 255
    refresh_spacing
  end

  def hide
    @actor_command_window.hide
    @command_help_window.hide
    @command_splash_window.hide
    #@background_bar.opacity = 0
  end

  def refresh_spacing
    @actor_command_window.refresh_position
    offset = Graphics.width - @actor_command_window.width
    @command_help_window.width = offset
    @command_splash_window.update_command_origin(offset)
  end

  def needs_update?
    @actor_command_window.visible && @command_help_window.processing_text?
  end

  def update
    @command_help_window.update_text
  end

  def dispose
    @command_help_window.dispose
    @actor_command_window.dispose
    @command_splash_window.dispose
    @background_bar.dispose
  end

end

#==============================================================================
# ■ BattleUI_Button
#-----------------------------------------------------------------------------
# Define the actor command buttons on the Battle UI Bar.
#==============================================================================
class BattleUI_Button

  def initialize(viewport, name)
    @button = Sprite.new(viewport)
    @sprite_name = name.to_s
    @selected = false
    refresh_button_image(@sprite_name)
  end

  def refresh_button_image(name)
    @sprite_name = name.to_s
    @selected ? select_button : unselect_button
  end

  def set_position(index, button_max)
    padding = Revoked::BattleUI::COMMAND_PADDING
    offset = (button_max - index) * Revoked::BattleUI::BUTTON_WIDTH
    space = (button_max - index - 1) * Revoked::BattleUI::COMMAND_SPACING
    @button.x = Graphics.width - offset - padding - space
    @button.y = Revoked::BattleUI::COMMAND_Y + padding
  end

  def select_button
    @button.bitmap = Cache.battle_ui("selected_#{@sprite_name}")
    @selected = true
  end

  def unselect_button
    @button.bitmap = Cache.battle_ui("off_#{@sprite_name}")
    @selected = false
  end

  def dispose
    @button.dispose
  end

end

#=============================================================================
# ■ Window_BattleUI_Help
#-----------------------------------------------------------------------------
# Description of the selected command. Characters are drawn separately.
#=============================================================================
class Window_BattleUI_Help < Window_Base

  def initialize(w)
    super(0, Graphics.height - 68, w, 68)
    self.opacity = 0
    self.arrows_visible = false
    set_desc("")
  end

  def set_desc(text)
    p(text)
    contents.clear
    @text = text
    @pos = {:x => 0, :y => 0, :new_x => 0, :height => 24}
  end

  def standard_padding ; 14 end

  def processing_text?
    return !@text.empty?
  end

  def update_text
    process_character(@text.slice!(0, 1), @text, @pos) unless @text.empty?
  end

end

#==============================================================================
# ■ Window_BattleUI_Splash
#-----------------------------------------------------------------------------
# A window for the name of the currently selected actor command.
#==============================================================================
class Window_BattleUI_Splash < Window_Base

  def initialize(offset_x)
    sw = Revoked::BattleUI::SPLASH_WIDTH
    super(offset_x - sw, Graphics.height - 68, sw, 68)
    self.opacity = 0
    set_splash("ATTACK")
  end

  def set_splash(command = "ATTACK")
    @text = command
    contents.clear
    contents.font.size = Revoked::BattleUI::FONT_LARGE
    contents.font.color = Revoked::BattleUI::FONT_WHITE
    contents.font.color.alpha = Revoked::BattleUI::SPLASH_OPACITY
    contents.draw_text(0, 0, contents.width, contents.height, @text.upcase, 2)
  end

  def update_command_origin(command_x)
    self.x = command_x - Revoked::BattleUI::SPLASH_WIDTH
  end

end

#==============================================================================
# ■ Window_BattleSkill
#==============================================================================
class Window_BattleSkill < Window_SkillList

  # Override
  def initialize(help_window, info_viewport)
    w = 208
    x = Graphics.width - w
    y = vertical_offset
    super(x, y, w, height_calc)
    self.visible = false
    self.back_opacity = 255
    @help_window = help_window
    @info_viewport = info_viewport
  end

  # Overrides
  def page_row_max ; 10 ; end
  def standard_padding ; 8 ; end
  def col_max ; 1 ; end
  def vertical_offset ; Graphics.height - 66 ; end

  # Calculate the window height and check for the maximum number of lines.
  def height_calc
    lines = [@data.length, page_row_max].min rescue page_row_max
    return lines * line_height + standard_padding * 2
  end

  def refresh_position
    self.height = height_calc
    self.y = vertical_offset - height
    self.x = Graphics.width - 208
    p([height, y])
  end

  alias rvkd_battleui_battleskill_refresh refresh
  def refresh
    rvkd_battleui_battleskill_refresh
    refresh_position
  end

end

#==============================================================================
# ■ Window_BattleItem
#==============================================================================
class Window_BattleItem < Window_ItemList

  # Override
  def initialize(help_window, info_viewport)
    w = 208
    x = Graphics.width - w
    y = vertical_offset
    super(x, y, w, height_calc)
    self.visible = false
    self.back_opacity = 255
    @help_window = help_window
    @info_viewport = info_viewport
  end

  # Overrides
  def page_row_max ; 10 ; end
  def standard_padding ; 8 ; end
  def col_max ; 1 ; end
  def vertical_offset ; Graphics.height - 66 ; end

  # Calculate the window height and check for the maximum number of lines.
  def height_calc
    lines = [@data.length, page_row_max].min rescue page_row_max
    return lines * line_height + standard_padding * 2
  end

  def refresh_position
    self.height = height_calc
    self.y = vertical_offset - height
    self.x = Graphics.width - 208
    p([height, y])
  end

  alias rvkd_battleui_battleitem_refresh refresh
  def refresh
    rvkd_battleui_battleitem_refresh
    refresh_position
  end

end

#==============================================================================
# ■ Window_Base
#==============================================================================
class Window_Base < Window

  alias rvkd_battleui_window_base_initialize initialize
  def initialize(x, y, width, height)
    rvkd_battleui_window_base_initialize(x, y, width, height)
    self.back_opacity = 255
    self.opacity = 255
  end

end
