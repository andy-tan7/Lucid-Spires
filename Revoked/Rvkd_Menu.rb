#===========================================================================
# ** Revoked Custom Scene_Menu
#---------------------------------------------------------------------------
#  This class sets up a custom menu screen using images.
#===========================================================================
module Revoked
  module Menu
    TAB = {:x     => 860, :y      => 62,    # Menu_Command Tabs
           :width => 92,  :height => 39,
           :pad   => 8,   :info_y => -32}

    TIME = {:cursor => 4,                   # Menu_Command Sprites
            :text   => 4,
            :shadow => 12,
            :splash => 12}

    STATUS = {:x => 33, :y => 62,           # MenuStatus
              :level_x   => 58,
              :class_y   => 200,
              :card_w    => 126,
              :bar_width => 112}

    HP_BAR = {:bar_x  => 6, :bar_y  => 237, # MenuStatus CharacterCard
              :fill_x => 7, :fill_y => 238,
              :diam_x => 8, :diam_y => 226,
              :text_x => 6, :text_y => 224}

    MP_BAR = {:bar_x  => 6, :bar_y  => 256, # MenuStatus CharacterCard
              :fill_x => 7, :fill_y => 257,
              :diam_x => 8, :diam_y => 245,
              :text_x => 6, :text_y => 243}

    TP_BAR = {:ary_x =>  6, :ary_y  => 268, :offset_x => 14}

    FONT_NAME = "EB Garamond 08 Standard Digit"
    FONT_LIGHT = Color.new(100,85,75,255)
    FONT_DARK = Color.new(24,24,24,255)
    FONT_BROWN = Color.new(56,48,40,255)

    FONT_FADE = Color.new(48,48,48,48)
    FONT_SMALL = 21
    FONT_MENULIST = 20
    FONT_REGULAR = 24
    FONT_MEDIUM = 28
    FONT_LEVEL = 36
    FONT_LARGE = 70

    GOLD_ICON = 361

    SPLASH = [
      ["Titles",     "View and adjust character titles."],                # 0
      ["Abilities",  "Access character abilities and passive skills."],   # 1
      ["Equipment",  "Equip weapons, armour, and accessories."],          # 2
      ["Inventory",  "Access items and equip flasks."],                   # 3
      ["Formation",  "Adjust party members and reposition characters."],  # 4
      ["Status",     "View detailed accounts of character conditions."],  # 5
      ["Configure",  "Modify game and system settings."]                  # 6
    ]
  end
end

module Vocab
  def self.titles;  "Titles";   end
  def self.config;  "Config";   end
end

module Cache
  def self.menus(filename)
    load_bitmap("Graphics/Menus/", filename)
  end
end

class Window

  def back_opacity ; 255 end

  def opacity ; 255 end

end


#=============================================================================
# ■ Scene_Menu
#=============================================================================
class Scene_Menu < Scene_MenuBase

  #alias: start
  alias rvkd_custom_scm_start start
  def start
    rvkd_custom_scm_start
    create_playtime_window
    create_map_window
  end

  #overwrite: create_background
  def create_background
    @background_sprite = Sprite.new
    @background_sprite.bitmap = Cache.menus("Menu_Back")
    @background_sprite.x = 0
    @background_sprite.y = 0
    @background_sprite.opacity = 255
  end

  #overwrite: create_command_window
  def create_command_window
    @command_window = Window_MenuCommand.new
    @command_window.set_handler(:titles,    method(:return_scene))
    @command_window.set_handler(:skill,     method(:command_personal))
    @command_window.set_handler(:equip,     method(:command_personal))
    @command_window.set_handler(:item,      method(:command_item))
    @command_window.set_handler(:formation, method(:command_formation))
    @command_window.set_handler(:status,    method(:command_personal))
    @command_window.set_handler(:config,    method(:return_scene))
    @command_window.set_handler(:cancel,    method(:return_scene))
  end

  # #overwrite: create_status_window
  # def create_status_window
  #   @status_window = Window_MenuStatus.new(0, 0)
  #   @status_window.opacity = 0
  # end

  #overwrite: create_gold_window
  def create_gold_window
    @gold_window = Window_Gold.new
  end

  def create_playtime_window
    @playtime_window = Window_PlayTime.new
  end

  def create_map_window
    @map_window = Window_MenuMapName.new
  end

  #alias: dispose_all_windows
  alias rvkd_custom_scm_dispose_all_windows dispose_all_windows
  def dispose_all_windows
    @command_window.dispose_selector
    @command_window.dispose_sprites
    @status_window.dispose_sprites
    rvkd_custom_scm_dispose_all_windows
  end

end # ★ Scene_Menu

#=============================================================================
# ■ Window_Command
#=============================================================================
class Window_Command < Window_Selectable

  #overwrite: initialize
  def initialize(x,y)
    clear_command_list
    make_command_list
    super(x, y, window_width, window_height)
    refresh
    select(0) unless self.is_a?(Window_MenuCommand)
    activate
  end

end # ★ Window_Command

#=============================================================================
# ■ Window_MenuCommand
#=============================================================================
class Window_MenuCommand < Window_Command

  #overwrite: initialize
  def initialize
    clear_command_list
    make_command_tiles
    make_command_list
    make_command_texts
    super(Graphics.width, Graphics.height)
    refresh
    activate
    select_last_index
  end

  class << self
    alias rvkd_custom_scm_init_command_position init_command_position
    def init_command_position
      rvkd_custom_scm_init_command_position
      @@last_command_index = 0
    end
  end

  def select_last_index
    select(@@last_command_index,true)
  end

  #alias: select
  alias rvkd_custom_scm_select select
  def select(index,instant = false)
    @command_tiles[self.index].unselect(instant)
    @command_texts[self.index].unselect(instant)
    rvkd_custom_scm_select(index)
    @command_tiles[index].select(instant)
    @command_texts[index].select(instant)
    @@selector.select(index,instant)
    @splash_desc.set_desc(Revoked::Menu::SPLASH[index][1].dup)
    @splash_text.set_splash(Revoked::Menu::SPLASH[@index][0], instant)
  end

  #alias: process_ok
  alias rvkd_custom_scm_process_ok process_ok
  def process_ok
    @@last_command_index = self.index
    rvkd_custom_scm_process_ok
  end

  def dispose_selector
    @@selector.dispose
    @@selector = nil
  end

  def dispose_sprites
    @command_tiles.each {|tile| tile.dispose}
    @command_texts.each {|text| text.dispose}
    @splash_desc.dispose
    @splash_text.dispose
  end

  #overwrite: make_command_list
  def make_command_list
    add_command(Vocab::titles,    :titles,     main_commands_enabled)
    add_command(Vocab::skill,     :skill,      main_commands_enabled)
    add_command(Vocab::equip,     :equip,      main_commands_enabled)
    add_command(Vocab::item,      :item,       main_commands_enabled)
    add_command(Vocab::formation, :formation,  formation_enabled)
    add_command(Vocab::status,    :status,     main_commands_enabled)
    add_command(Vocab::config,    :config,     true)
  end

  def make_command_tiles
    @@selector ||= RvkdMenu_Cursor.new(@viewport,@@last_command_index)
    @command_tiles = []
    7.times {|i| @command_tiles.push(RvkdMenu_Tab.new(i,@viewport,@selector))}
  end

  def make_command_texts
    @splash_text ||= Window_MenuTabSplash.new(@@last_command_index)
    @splash_desc ||= Window_MenuTabDesc.new
    @command_texts = []
    7.times {|i|@command_texts.push(Window_MenuTabText.new(i,command_name(i)))}
  end

  #alias: update
  alias rvkd_custom_scm_wmc_update update
  def update
    rvkd_custom_scm_wmc_update
    @@selector.slide if @@selector.slide_frames > 0
    @command_tiles.each {|tile| tile.update_shadow if tile.fading? }
    @command_texts.each {|text| text.slide if text.slide_frames > 0 }
    @splash_desc.update_text if @splash_desc.processing_text?
    @splash_text.slide if @splash_text.slide_frames > 0
  end

end # ★ Window_MenuCommand

#=============================================================================
# ■ RvkdMenu_Tab
#-----------------------------------------------------------------------------
# Base image for menu command tiles, created for each command.
#=============================================================================
class RvkdMenu_Tab < Sprite

  def initialize(index, viewport, selector)
    super(viewport)
    @index = index
    self.bitmap = Cache.menus("Menu_TabBase")
    self.x = Revoked::Menu::TAB[:x]
    self.y = Revoked::Menu::TAB[:y] + (Revoked::Menu::TAB[:height] * index)
    self.z = 5
    @shadow = RvkdMenu_TabShadow.new(viewport, selector, @index)
  end

  def select(instant = false)
    @shadow.select(instant)
  end

  def unselect(instant = false)
    @shadow.unselect(instant)
  end

  def fading?
    @shadow.fading?
  end

  def update_shadow
    @shadow.slide
  end

  #alias: dispose
  alias rvkd_custom_scm_menutab_dispose dispose
  def dispose
    @shadow.dispose
    rvkd_custom_scm_menutab_dispose
  end

end # ★ RvkdMenu_Tab

#=============================================================================
# ■ RvkdMenu_Cursor
#-----------------------------------------------------------------------------
# Cursor image. Smoothly slides to the next command when moved.
#=============================================================================
class RvkdMenu_Cursor < Sprite

  attr_reader :slide_frames
  def initialize(viewport, index = 0)
    super(viewport)
    @index = index ? index : 0
    @destination = nil
    @slide_frames = 0
    self.bitmap = Cache.menus("Menu_TabSelect")
    self.x = Revoked::Menu::TAB[:x]
    self.y = Revoked::Menu::TAB[:y] + (Revoked::Menu::TAB[:height] * index)
    self.z = 6
  end

  def select(index = 0, instant = false)
    @index = index
    if instant
      self.y = Revoked::Menu::TAB[:y] + (Revoked::Menu::TAB[:height] * index)
      return
    end
    @slide_frames = Revoked::Menu::TIME[:cursor]
    @destination = Revoked::Menu::TAB[:y] + Revoked::Menu::TAB[:height] * index
  end

  def slide
    self.y += (@destination - self.y) / @slide_frames
    @slide_frames -= 1
    if @slide_frames <= 0
      self.y = @destination
      @destination = nil
    end
  end

end # ★ RvkdMenu_Cursor

#=============================================================================
# ■ RvkdMenu_TabShadow
#-----------------------------------------------------------------------------
# Shadow beneath each menu tab. Opacity smoothly increases for selected tabs.
#=============================================================================
class RvkdMenu_TabShadow < Sprite

  def initialize(viewport, selector, index = 0)
    super(viewport)
    @index = index
    @dest_opacity = nil
    @slide_frames = 0
    self.bitmap = Cache.menus("Menu_TabShadow")
    self.opacity = 0
    self.x = Revoked::Menu::TAB[:x]
    self.y = Revoked::Menu::TAB[:y] + (Revoked::Menu::TAB[:height] * index)
    self.z = 0
  end

  def select(instant = false)
    unless instant
      @dest_opacity = 255
      @slide_frames = Revoked::Menu::TIME[:shadow]
    else
      self.opacity = 255
    end
  end

  def unselect(instant = false)
    unless instant
      @dest_opacity = 0
      @slide_frames = Revoked::Menu::TIME[:shadow]
    else
      self.opacity = 0
    end
  end

  def fading?
    return @slide_frames > 0
  end

  def slide
    self.opacity += (@dest_opacity - self.opacity) / @slide_frames
    @slide_frames -= 1
    if @slide_frames <= 0
      self.opacity = @dest_opacity
      @dest_opacity = nil
    end
  end

end # ★ RvkdMenu_TabShadow

#=============================================================================
# ■ Window_MenuTabText
#-----------------------------------------------------------------------------
# Text drawn for each tab. Slides to the right when tab selected.
#=============================================================================
class Window_MenuTabText < Window_Base

  attr_reader :slide_frames
  def initialize(index, text = "Missing")
    super(0,0,Revoked::Menu::TAB[:width],Revoked::Menu::TAB[:height])
    @text = text
    @dest_x = nil
    @slide_frames = 0
    @underline = RvkdMenu_TabUnderline.new(@viewport,index)
    self.opacity = 0
    self.x = Revoked::Menu::TAB[:x]
    self.y = Revoked::Menu::TAB[:y] + (Revoked::Menu::TAB[:height] * index)
    self.z = 15
    contents.font.size = Revoked::Menu::FONT_MEDIUM
    contents.font.name = Revoked::Menu::FONT_NAME
    contents.font.outline = false
    contents.font.shadow = false
    contents.font.color = Revoked::Menu::FONT_LIGHT
    rx = Revoked::Menu::TAB[:pad]
    rw = Revoked::Menu::TAB[:width]
    draw_text(Rect.new(rx, 3, rw, 32), @text, 0)
  end

  def standard_padding; 0 end

  def select(instant = false)
    @underline.select(instant)
    x = Revoked::Menu::TAB[:x] + Revoked::Menu::TAB[:width]
    unless instant
      @dest_x = x - contents.text_size(@text).width - 2*Revoked::Menu::TAB[:pad]
      @slide_frames = Revoked::Menu::TIME[:text]
    else
      self.x = x - contents.text_size(@text).width - 2*Revoked::Menu::TAB[:pad]
    end
  end

  def unselect(instant = false)
    @underline.unselect(instant)
    unless instant
      @dest_x = Revoked::Menu::TAB[:x]
      @slide_frames = Revoked::Menu::TIME[:text]
    else
      self.x = Revoked::Menu::TAB[:x]
    end
  end

  def slide
    self.x += (@dest_x - self.x) / @slide_frames
    @underline.slide(@slide_frames)
    @slide_frames -= 1
    if @slide_frames <= 0
      self.x = @dest_x
      @dest_x = nil
    end
  end

  #alias: dispose
  alias rvkd_custom_scm_menutab_dispose dispose
  def dispose
    @underline.dispose
    rvkd_custom_scm_menutab_dispose
  end

end # ★ Window_MenuTabText

#=============================================================================
# ■ Window_MenuTabSplash
#-----------------------------------------------------------------------------
# Large, transparent text at the top of the menu. Fades in when adjusted.
#=============================================================================
class Window_MenuTabSplash < Window_Base

  attr_reader :slide_frames
  def initialize(index = 0)
    super(0, 0, 352, 72)
    @text_opacity = 0
    @slide_frames = 0
    self.opacity = 0
    self.x = 284
    self.y = 4
    set_splash(Revoked::Menu::SPLASH[index][0])
  end

  def set_splash(command = "MENU", instant = false)
    @text = command
    @text_opacity = 0
    if instant || @slide_frames > 0
      self.y = -15
      @dest_y = -15
      @text_opacity = 60
    else
      self.y = -15
      @dest_y = -15
      @dest_opacity = 60
      @slide_frames = Revoked::Menu::TIME[:splash]
    end
    contents.clear
    contents.font.size = Revoked::Menu::FONT_LARGE
    contents.font.name = Revoked::Menu::FONT_NAME
    contents.font.outline = false
    contents.font.shadow = false
    contents.font.color = Revoked::Menu::FONT_FADE
    contents.font.color.alpha = @text_opacity
    contents.draw_text(0,0, contents.width, contents.height, @text.upcase, 2)
  end

  def slide
    @text_opacity += (@dest_opacity - @text_opacity) / @slide_frames
    contents.clear
    contents.font.color = Revoked::Menu::FONT_FADE
    contents.font.color.alpha = @text_opacity
    contents.draw_text(0,0, contents.width, contents.height, @text.upcase, 2)
    self.y += (@dest_y - self.y) / @slide_frames
    @slide_frames -= 1
    if @slide_frames <= 0
      self.y = @dest_y
      @text_opacity = @dest_opacity
      @dest_opacity = nil
      @dest_y = nil
    end
  end

  def standard_padding ; 0 end

end # ★ Window_MenuTabSplash

#=============================================================================
# ■ Window_MenuTabDesc
#-----------------------------------------------------------------------------
# Description of the selected tab. Characters are drawn separately.
#=============================================================================
class Window_MenuTabDesc < Window_Base

  def initialize(index = 0)
    super(80, 24, 416, 48)
    self.opacity = 0
    contents.font.size = Revoked::Menu::FONT_SMALL
    contents.font.name = Revoked::Menu::FONT_NAME
    contents.font.outline = false
    contents.font.shadow = false
    contents.font.color = Revoked::Menu::FONT_DARK
    set_desc(index)
  end

  def set_desc(text = "Description text.")
    contents.clear
    @text = text
    @pos = {:x => 0, :y => 0, :new_x => 0, :height => 24}
  end

  def standard_padding ; 0 end

  def processing_text?
    return !@text.empty?
  end

  def update_text
    process_character(@text.slice!(0, 1), @text, @pos) unless @text.empty?
  end

end # ★ Window_MenuTabDesc

#=============================================================================
# ■ RvkdMenu_TabUnderline
#-----------------------------------------------------------------------------
# Subtle underline that slides in under the TabText of the selected tab.
#=============================================================================
class RvkdMenu_TabUnderline < Sprite

  attr_accessor :dest_x
  def initialize(viewport, index)
    super(viewport)
    self.bitmap = Cache.menus("Menu_TabSelectLine")
    self.opacity = 0
    self.x = Revoked::Menu::TAB[:x] - 48
    self.y = Revoked::Menu::TAB[:y] + (Revoked::Menu::TAB[:height] * index) + 1
    self.z = 16
    @dest_x = nil
    @dest_opacity = nil
  end

  def select(instant = false)
    unless instant
      @dest_x = Revoked::Menu::TAB[:x]
      @dest_opacity = 255
    else
      self.x = Revoked::Menu::TAB[:x]
      self.opacity = 255
    end
  end

  def unselect(instant = false)
    unless instant
      @dest_x = Revoked::Menu::TAB[:x] - 32
      @dest_opacity = 0
    else
      self.x = Revoked::Menu::TAB[:x] - 32
      self.opacity = 0
    end
  end

  def slide(slide_frames)
    self.x += (@dest_x - self.x) / slide_frames
    self.opacity += (@dest_opacity - self.opacity) / slide_frames
    if slide_frames <= 1
      self.x = @dest_x
      self.opacity = @dest_opacity
      @dest_x = nil
      @dest_opacity = nil
    end
  end

end # ★ RvkdMenu_TabUnderline

#=============================================================================
# ■ Window_PlayTime
#=============================================================================
class Window_PlayTime < Window_Base

  def initialize
    super(0, 0, 160, 24)
    self.opacity = 0
    self.x = (Graphics.width * 0.875).to_i
    self.y = Graphics.height + Revoked::Menu::TAB[:info_y]
    contents.font.size = Revoked::Menu::FONT_SMALL
    contents.font.name = Revoked::Menu::FONT_NAME
    contents.font.outline = false
    contents.font.shadow = false
    contents.font.color = Revoked::Menu::FONT_DARK
    refresh
  end

  def standard_padding ; 0 end

  def refresh
    contents.clear
    @time = $game_system.playtime
    display_time = $game_system.playtime_s
    contents.draw_text(4, 0, contents.width, contents.height, display_time, 0)
  end

  def update
    super
    refresh if @time != $game_system.playtime
  end

end # ★ Window_PlayTime

#=============================================================================
# ■ Window_Gold
#=============================================================================
class Window_Gold < Window_Base

  #overwrite: initialize
  def initialize
    super(0, 0, 96, 24)
    self.opacity = 0
    self.x = (Graphics.width * 0.7).to_i
    self.y = Graphics.height + Revoked::Menu::TAB[:info_y]
    contents.font.size = Revoked::Menu::FONT_SMALL
    contents.font.name = Revoked::Menu::FONT_NAME
    contents.font.outline = false
    contents.font.shadow = false
    contents.font.color = Revoked::Menu::FONT_DARK
    refresh
  end

  def standard_padding ; 0 end

  #overwrite: draw_currency_value
  def draw_currency_value(value, unit, x, y, width)
    #p(width)
    draw_text(x + 26, y, width, line_height, value, 0)
    draw_icon(Revoked::Menu::GOLD_ICON, x, y - 2, enabled = true)
    #draw_text(x, y, width, line_height, unit, 2)
  end

end # ★ Window_Gold

#=============================================================================
# ■ Window_MenuMapName
#=============================================================================
class Window_MenuMapName < Window_Base

  def initialize
    super(0, 0, 288, 24)
    self.opacity = 0
    self.x = 80
    self.y = Graphics.height + Revoked::Menu::TAB[:info_y]
    contents.font.size = Revoked::Menu::FONT_SMALL
    contents.font.name = Revoked::Menu::FONT_NAME
    contents.font.outline = false
    contents.font.shadow = false
    contents.font.color = Revoked::Menu::FONT_DARK
    refresh
  end

  def standard_padding ; 0 end

  def refresh
    contents.clear
    text = $data_mapinfos[$game_map.map_id].name
    contents.draw_text(0, 0, 288, line_height, text, 0)
  end

end # ★ Window_MenuMapName


#=============================================================================
# ■ Window_MenuStatus
#=============================================================================
class Window_MenuStatus < Window_Selectable

  def window_width     ; 504 end
  def window_height    ; 288 end
  def standard_padding ; 0   end

  def item_width  ; Revoked::Menu::STATUS[:card_w] end
  def item_height ; 288 end
  def row_max ; 1 end
  def col_max ; 4 end
  def spacing ; 0 end

  #alias: initialize
  alias rvkd_custom_scm_wms_initialize initialize
  def initialize(x,y)
    @character_cards = []
    rvkd_custom_scm_wms_initialize(x,y)
    self.opacity = 0
    self.x = Revoked::Menu::STATUS[:x]
    self.y = Revoked::Menu::STATUS[:y]
  end

  def dispose_sprites
    @character_cards.each {|card| card.dispose}
  end

  # alias rvkd_custom_scm_wms_show activate
  # def activate
  #   show_cards
  #   rvkd_custom_scm_wms_show
  # end

  # alias rvkd_custom_scm_wms_hide deactivate
  # def deactivate
  #   hide_cards
  #   rvkd_custom_scm_wms_hide
  # end
  #
  # def show_cards
  #   @character_cards.each {|card| card.show_sprites}
  # end
  #
  # def hide_cards
  #   @character_cards.each {|card| card.hide_sprites}
  # end

  #overwrite: draw_item
  def draw_item(index)
    actor = $game_party.members[index]
    enabled = $game_party.battle_members.include?(actor)
    @character_cards.push(RvkdMenu_CharacterCard.new(@viewport,index,actor))
    rect = item_rect(index)
    draw_item_background(index)
    draw_actor_simple_status(actor, rect.x, rect.y)
  end

  #overwrite: draw_actor_simple_status
  def draw_actor_simple_status(actor, x, y)
    draw_actor_level(actor, x + Revoked::Menu::STATUS[:level_x], y)
    draw_actor_icons(actor, x, y + line_height * 2)
    contents.font.size = Revoked::Menu::FONT_SMALL
    draw_actor_class(actor, x + 8, y + Revoked::Menu::STATUS[:class_y])
    draw_actor_hp(actor, x, y)
    draw_actor_mp(actor, x, y)
  end

  #overwrite: draw_actor_level
  def draw_actor_level(actor, x, y)
    contents.font.outline = false
    contents.font.shadow = false
    contents.font.name = Revoked::Menu::FONT_NAME
    contents.font.color = Revoked::Menu::FONT_DARK
    contents.font.color.alpha = 150
    contents.font.size = Revoked::Menu::FONT_SMALL
    draw_text(x, y, 32, 24, "LV", 1)
    contents.font.size = Revoked::Menu::FONT_LEVEL
    draw_text(x, y - 4, 92, 32, actor.level, 1)
  end


  #overwrite: draw_actor_hp(actor, x, y, width = 124)
  def draw_actor_hp(actor, x, y, width = Revoked::Menu::STATUS[:bar_width])
    contents.font.outline = true
    contents.font.size = Revoked::Menu::FONT_SMALL
    contents.font.name = Revoked::Menu::FONT_NAME
    contents.font.color = hp_color(actor)
    offset_x = Revoked::Menu::HP_BAR[:text_x]
    offset_y = Revoked::Menu::HP_BAR[:text_y]
    draw_text(x + offset_x, y + offset_y, width, line_height, "#{actor.hp}", 2)
  end

  #overwrite: draw_actor_mp(actor, x, y, width = 124)
  def draw_actor_mp(actor, x, y, width = Revoked::Menu::STATUS[:bar_width])
    contents.font.size = Revoked::Menu::FONT_SMALL
    contents.font.name = Revoked::Menu::FONT_NAME
    contents.font.outline = true
    contents.font.color = mp_color(actor)
    offset_x = Revoked::Menu::MP_BAR[:text_x]
    offset_y = Revoked::Menu::MP_BAR[:text_y]
    draw_text(x + offset_x, y + offset_y, width, line_height, "#{actor.mp}", 2)
  end

  # def hp_gauge_color1 ; Color.new(182,38,38,255) end
  # def hp_gauge_color2 ; Color.new(244,185,30,255) end

  # #overwrite: draw_gauge(x, y, width, rate, color1, color2)
  # def draw_gauge(x, y, width, rate, color1, color2)
  #   fill_w = (width * rate).to_i
  #   gauge_y = y + line_height - 8
  #   contents.fill_rect(x, gauge_y, width, 6, gauge_back_color)
  #   contents.gradient_fill_rect(x, gauge_y, fill_w, 6, color1, color2)
  # end

end

class RvkdMenu_CharacterCard < Sprite

  def initialize(viewport,index,actor)
    super(viewport)
    default = Cache.menus("MenuCard_Template")
    self.bitmap = Cache.menus("MenuCard_#{actor.name}") rescue default
    self.x = Revoked::Menu::STATUS[:x] + index * Revoked::Menu::STATUS[:card_w]
    self.y = Revoked::Menu::STATUS[:y]
    @actor = actor
    make_hp(index)
    make_mp(index)
    make_tp(index, actor)
  end

  def make_hp(index)
    offset_x = Revoked::Menu::STATUS[:x]
    offset_y = Revoked::Menu::STATUS[:y]
    width = Revoked::Menu::STATUS[:card_w]

    @hp_bar = Sprite.new(@viewport)
    @hp_bar.bitmap = Cache.menus("Menu_HPBar")
    @hp_bar.x = offset_x + Revoked::Menu::HP_BAR[:bar_x] + index * width
    @hp_bar.y = offset_y + Revoked::Menu::HP_BAR[:bar_y]
    @hp_bar.z = 20

    @hp_diamond = Sprite.new(@viewport)
    @hp_diamond.bitmap = Cache.menus("Menu_HPDiamond")
    @hp_diamond.x = offset_x + Revoked::Menu::HP_BAR[:diam_x] + index * width
    @hp_diamond.y = offset_y + Revoked::Menu::HP_BAR[:diam_y]
    @hp_diamond.z = 22

    @hp_fill = RvkdMenu_StatBar.new(@viewport, :hp, @actor)
    @hp_fill.bitmap = Cache.menus("Menu_HPFill")
    @hp_fill.x = offset_x + Revoked::Menu::HP_BAR[:fill_x] + index * width
    @hp_fill.y = offset_y + Revoked::Menu::HP_BAR[:fill_y]
    @hp_fill.z = 21
  end

  def make_mp(index)
    offset_x = Revoked::Menu::STATUS[:x]
    offset_y = Revoked::Menu::STATUS[:y]
    width = Revoked::Menu::STATUS[:card_w]

    @mp_bar = Sprite.new(@viewport)
    @mp_bar.bitmap = Cache.menus("Menu_MPBar")
    @mp_bar.x = offset_x + Revoked::Menu::MP_BAR[:bar_x] + index * width
    @mp_bar.y = offset_y + Revoked::Menu::MP_BAR[:bar_y]
    @mp_bar.z = 20

    @mp_diamond = Sprite.new(@viewport)
    @mp_diamond.bitmap = Cache.menus("Menu_MPDiamond")
    @mp_diamond.x = offset_x + Revoked::Menu::MP_BAR[:diam_x] + index * width
    @mp_diamond.y = offset_y + Revoked::Menu::MP_BAR[:diam_y]
    @mp_diamond.z = 22

    @mp_fill = RvkdMenu_StatBar.new(@viewport, :mp, @actor)
    @mp_fill.bitmap = Cache.menus("Menu_MPFill")
    @mp_fill.x = offset_x + Revoked::Menu::MP_BAR[:fill_x] + index * width
    @mp_fill.y = offset_y + Revoked::Menu::MP_BAR[:fill_y]
    @mp_fill.z = 21
  end

  def make_tp(index, actor)
    @tp_diamonds = []
    max_tp = actor.max_tp
    cur_tp = actor.tp_rise

    offset_x = Revoked::Menu::STATUS[:x]
    offset_y = Revoked::Menu::STATUS[:y]
    width = Revoked::Menu::STATUS[:card_w]
    b_x = Revoked::Menu::TP_BAR[:ary_x]
    d_x = Revoked::Menu::TP_BAR[:offset_x]

    # cur_tp.times do |i|
    #   frame = Sprite.new(@viewport)
    #   frame.bitmap = Cache.menus("Menu_ZP_Full")
    #   frame.x = offset_x + i * d_x + index * width + b_x
    #   frame.y = offset_y + Revoked::Menu::TP_BAR[:ary_y]
    #   frame.z = 22
    #   @tp_diamonds.push(frame)
    # end
    max_tp.times do |i|
      frame = Sprite.new(@viewport)
      frame.bitmap = Cache.menus("Menu_ZP_#{i >= cur_tp ? "Empty" : "Full"}")
      frame.x = offset_x + i * d_x + index * width + b_x
      frame.y = offset_y + Revoked::Menu::TP_BAR[:ary_y]
      frame.z = 22
      @tp_diamonds.push(frame)
      #i += 1
    end

    # def draw_tp(index, i, fill = false)
    #   offset_x = Revoked::Menu::STATUS[:x]
    #   offset_y = Revoked::Menu::STATUS[:y]
    #   width = Revoked::Menu::STATUS[:card_w]
    #   b_x = Revoked::Menu::TP_BAR[:ary_x]
    #   d_x = Revoked::Menu::TP_BAR[:offset_x]
    #   frame = Sprite.new(@viewport)
    #   frame.bitmap = Cache.menus("Menu_ZP_#{fill ? "Full" : "Empty"}")
    #   frame.x = offset_x + i * d_x + index * width + b_x
    #   frame.y = offset_y + Revoked::Menu::TP_BAR[:ary_y]
    #   frame.z = 22
    #   @tp_diamonds.push(frame)
    # end

  end

  # def show_sprites
  #   [@hp_bar,@hp_fill,@hp_diamond,@mp_bar,@mp_fill,@mp_diamond].each do |item|
  #     item.visible = true
  #     item.opacity = 255
  #   end
  # end
  #
  # def hide_sprites
  #   [@hp_bar,@hp_fill,@hp_diamond,@mp_bar,@mp_fill,@mp_diamond].each do |item|
  #     item.visible = false
  #     item.opacity = 0
  #   end
  # end

  alias rvkd_custom_scm_sprite_dispose dispose
  def dispose
    @hp_bar.dispose
    @hp_fill.dispose
    @hp_diamond.dispose
    @mp_bar.dispose
    @mp_fill.dispose
    @mp_diamond.dispose
    @tp_diamonds.each {|diamond| diamond.dispose}
    rvkd_custom_scm_sprite_dispose
  end

end

class RvkdMenu_StatBar < Sprite

  def initialize(viewport, symbol, actor)
    super(viewport)
    @symbol = symbol
    @actor = actor
    @current_ratio = stat_ratio
    init_bitmap(symbol)
    refresh
  end

  def init_bitmap(symbol)
    case @symbol
    when :hp; self.bitmap = Cache.menus("Menu_HPFill")
    when :mp; self.bitmap = Cache.menus("Menu_MPFill")
    #when :tp;
    end
  end

  def refresh
    width = self.bitmap.width
    height = self.bitmap.height
    width = width * @current_ratio
    self.src_rect.set(0, 0, width, height)
  end

  def stat_ratio
    return 1 unless @actor
    case @symbol
    when :hp; return @actor.hp_rate
    when :mp; return @actor.mp_rate
    #when :tp; return @actor.tp_rate
    end
  end

end
