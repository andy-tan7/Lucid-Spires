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
      :attack => "Strike with basic weapon attack.",
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
  end

  alias rvkd_battleui_scb_update_basic update_basic
  def update_basic
    rvkd_battleui_scb_update_basic
    @battle_ui.update if @battle_ui.needs_update?
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

  def window_width ; 368 end
  def row_max ; 1 end
  def col_max ; 6 end
  def line_height ; 59 end
  def item_width ; 59 end
  def spacing ; 4 end
  def standard_padding ; 4 end

  def window_width
    return 2 * standard_padding + col_max * (item_width + spacing) - spacing
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

  # Override
  def add_command_desc(n, s, d, enabled = true, ext = nil)
    @list.push({:name=>n, :symbol=>s, :desc=>d, :enabled=>enabled, :ext=>ext})
  end

  # Override adding commands.
  def add_attack_command
    desc = Revoked::BattleUI::Description[:attack]
    add_command_desc(Vocab::attack, :attack, desc, @actor.attack_usable?)
  end

  # Override
  def add_skill_commands
    @actor.added_skill_types.sort.each do |stype_id|
      name = $data_system.skill_types[stype_id]
      desc = Revoked::BattleUI::SType_Desc[stype_id]
      add_command_desc(name, :skill, desc, true, stype_id)
    end
  end

  # Override
  def add_guard_command
    desc = Revoked::BattleUI::Description[:guard]
    add_command_desc(Vocab::guard, :guard, desc, @actor.guard_usable?)
  end

  def add_item_command
    desc = Revoked::BattleUI::Description[:item]
    add_command_desc(Vocab::item, :item, desc)
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
  end

  # Override
  def update_help
  end

end

class BattleUI_Bar

  attr_reader :command_help_window

  def initialize(viewport, actor_command_window)
    @actor_command_window = actor_command_window

    help_width = Graphics.width - actor_command_window.width
    @command_help_window = Window_BattleUI_Help.new(help_width)
    @command_splash = Window_BattleUI_Splash.new(help_width)

    @actor_command_window.set_command_help(@command_help_window)
    @actor_command_window.set_splash_window(@command_splash)

    @background_bar = Sprite.new(viewport)
    @background_bar.bitmap = Cache.battle_ui("command_background")
    @background_bar.x = -10
    @background_bar.y = Graphics.height - 96

  end

  def needs_update?
    @actor_command_window.visible && @command_help_window.processing_text?
  end

  def update
    @command_help_window.update_text
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
