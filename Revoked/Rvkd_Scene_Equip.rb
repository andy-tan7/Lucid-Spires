# encoding: utf-8
module Vocab
  XPARAM = ["Accuracy",
            "Evasion",
            "Critical"]
  BPARAM = ["Might",
            "Arcana",
            "Vitality"]

  def self.xparam(xparam_id)
    XPARAM[xparam_id]
  end
  def self.bparam(bparam_id)
    BPARAM[bparam_id]
  end
end

module Revoked
  module Menu
    EQUIP_SLOT_ICON = [147,161,164,170,174,177,177]
    STAT_NAME_COLOR = FONT_BROWN
    STAT_NAME_SHADOW = false
    STAT_NAME_OUTLINE = false

    STAT_VALUE_COLOR = FONT_BROWN #Color.new(255,255,255,255)
    STAT_VALUE_SHADOW = false
    STAT_VALUE_OUTLINE = false

    COLOR_POWER_UP = Color.new(0,144,80,255)
    COLOR_POWER_DOWN = Color.new(192,0,12,255)

    module Equip
      HP_BAR = {:bar_x  => 74, :bar_y  => 18, #EquipCharacter card
                :fill_x => 75, :fill_y => 19,
                :diam_x => 76, :diam_y => 7,
                :text_x => -4, :text_y => 3}

      MP_BAR = {:bar_x  => 74, :bar_y  => 37, #EquipCharacter card
                :fill_x => 75, :fill_y => 38,
                :diam_x => 76, :diam_y => 26,
                :text_x => -4, :text_y => 22}

      TP_BAR = {:ary_x => 74, :ary_y => 49, :offset_x => 14}

      FACE_NAME = "menu64face"
      ITEM_WIDTH = 32

      ELEM_ICONS = [96,99,101,100,100,98,97,103,104]
      ELEM_POS = [[18,26],[50,10],[86,10],[118,26],
                  [18,98],[50,114],[86,114],[118,98]]
      ELEM_ID = [3,4,5,6,7,8,9,10]

      ICON_UP = 530
      ICON_DOWN = 531
      ICON_ARROW = 530
    end

  end
end

class Game_Actor < Game_Battler

  #override: equip_slots
  def equip_slots
    return [0,0,2,3,5,4,4] if dual_wield?
    return [0,1,2,3,5,4,4]
  end

end

class RPG::Armor < RPG::EquipItem

  def load_rvkd_etype_notetags
    self.note.split(/[\r\n]+/).each do |line|
      @etype_id = $1.to_i if line=~ /<\w*[ _]?type[:?][\s]?(\d+)>/i
    end
  end

end

#=============================================================================
# ■ module DataManager
#=============================================================================
class << DataManager
  alias rvkd_custom_equip_types_load_db load_database
  def load_database
    rvkd_custom_equip_types_load_db
    load_custom_equip_types
  end

  def load_custom_equip_types
    ($data_armors).compact.each do |item|
      item.load_rvkd_etype_notetags
    end
  end
end

#=============================================================================
# ■ Scene_Equip
#-----------------------------------------------------------------------------
# Equipment scene.
#=============================================================================
class Scene_Equip < Scene_MenuBase

  alias rvkd_custom_sceq_start start
  def start
    rvkd_custom_sceq_start
    create_attribute_window
    create_character_window
    create_preview_window
    command_equip
    @help_window.x = 64
    @help_window.y = 372
    @help_window.opacity = 24
  end

  alias rvkd_custom_sceq_command_clear command_clear
  def command_clear
    rvkd_custom_sceq_command_clear
    @attribute_window.refresh
    @character_window.refresh
    @preview_window.refresh
  end

  alias rvkd_custom_sceq_command_optimize command_optimize
  def command_optimize
    rvkd_custom_sceq_command_optimize
    @attribute_window.refresh
    @character_window.refresh
    @preview_window.refresh
  end

  alias rvkd_custom_sceq_on_item_ok on_item_ok
  def on_item_ok
    rvkd_custom_sceq_on_item_ok
    @attribute_window.refresh
    @character_window.refresh
    @preview_window.refresh
  end

  #override: on_actor_change -- remove command_window func
  #alias rvkd_custom_sceq_on_actor_change on_actor_change
  def on_actor_change
    @status_window.actor = @actor
    @slot_window.actor = @actor
    @item_window.actor = @actor
    @attribute_window.actor = @actor
    @character_window.actor = @actor
    @preview_window.actor = @actor
    @slot_window.activate
  end

  #override: create_command_window -- do nothing
  def create_command_window
  end

  #override: on_slot_cancel
  def on_slot_cancel
    return_scene
  end

  #overwrite: create_background
  def create_background
    @background_sprite = Sprite.new
    @background_sprite.bitmap = Cache.menus("Menu_Back")
    @background_sprite.x = 0
    @background_sprite.y = 0
    @background_sprite.z = 0
    @background_sprite.opacity = 255
  end

  #overwrite: create_status_window
  def create_status_window
    @status_window = Window_EquipStatus.new(432, 64)
    @status_window.viewport = @viewport
    @status_window.actor = @actor
  end

  #new: create_attribute_window
  def create_attribute_window
    @attribute_window = Window_EquipAttribute.new(432, 228)
    @attribute_window.viewport = @viewport
    @attribute_window.actor = @actor
    @slot_window.attribute_window = @attribute_window
    @item_window.attribute_window = @attribute_window
  end

  #new: create_character_window
  def create_character_window
    @character_window = Window_EquipCharacter.new(48, 64)
    @character_window.viewport = @viewport
    @character_window.actor = @actor
  end

  def create_preview_window
    @preview_window = Window_EquipPreview.new(256,64)
    @preview_window.viewport = @viewport
    @preview_window.actor = @actor
  end

  #overwrite: create_slot_window
  def create_slot_window
    @slot_window = Window_EquipSlot.new(48,144,198)
    @slot_window.viewport = @viewport
    @slot_window.help_window = @help_window
    @slot_window.status_window = @status_window
    @slot_window.actor = @actor
    @slot_window.set_handler(:ok,     method(:on_slot_ok))
    @slot_window.set_handler(:cancel, method(:on_slot_cancel))
    @slot_window.set_handler(:pagedown, method(:next_actor))
    @slot_window.set_handler(:pageup,   method(:prev_actor))
  end

  #overwrite: create_item_window
  def create_item_window
    @item_window = Window_EquipItem.new(256,228,166,114)
    @item_window.viewport = @viewport
    @item_window.help_window = @help_window
    @item_window.status_window = @status_window
    @item_window.actor = @actor
    @item_window.set_handler(:ok,     method(:on_item_ok))
    @item_window.set_handler(:cancel, method(:on_item_cancel))
    @slot_window.item_window = @item_window
  end

  #alias: dispose_all_windows
  alias rvkd_custom_sceq_dispose_all_windows dispose_all_windows
  def dispose_all_windows
    rvkd_custom_sceq_dispose_all_windows
    @character_window.dispose_sprites
    #@preview_window.dispose_sprites
  end

end

#=============================================================================
# ■ Window
#-----------------------------------------------------------------------------
# Aliased window methods.
#=============================================================================
class Window_Base < Window

  alias rvkd_custom_scm_window_background_panel dispose
  def dispose
    rvkd_custom_scm_window_background_panel
    @panel.dispose if @panel
  end

  def power_up_color; Revoked::Menu::COLOR_POWER_UP end
  def power_down_color; Revoked::Menu::COLOR_POWER_DOWN end

end
#=============================================================================
# ■ Window_EquipSlot
#-----------------------------------------------------------------------------
# Equipment slot window.
#=============================================================================
class Window_EquipSlot < Window_Selectable
  attr_reader :attribute_window

  alias rvkd_custom_sceq_window_equipslot_initialize initialize
  def initialize(x, y, width)
    rvkd_custom_sceq_window_equipslot_initialize(x, y, width)
    @panel = RvkdMenu_WindowPanel.new(self.x, self.y, 198, 198, @viewport)
    self.back_opacity = 0
  end



  def attribute_window=(attribute_window)
    @attribute_window = attribute_window
  end

  def window_height ; 198 end
  def standard_padding ; 8 end
  def line_height ; 26 end
  def visible_line_number ; 7 end

  #override: draw_item(index)
  #alias rvkd_custom_sceq_window_equipslot_draw_item draw_item
  def draw_item(index)
    return unless @actor
    contents.font.size = Revoked::Menu::FONT_SMALL
    contents.font.name = Revoked::Menu::FONT_NAME
    contents.font.color = Revoked::Menu::FONT_BROWN
    contents.font.color.alpha = 128
    contents.font.shadow = false
    contents.font.outline = false
    rect = item_rect_for_text(index)
    #draw_text(rect.x + 22, rect.y, 92, line_height, ":")
    #draw_icon(Revoked::Menu::EQUIP_SLOT_ICON[index], rect.x - 3, rect.y)
    draw_item_name(@actor.equips[index], rect.x + 28, rect.y, enable?(index))
  end

  #override: draw_item_name -- change colors, nil handling
  def draw_item_name(item, x, y, enabled = true, width = 172)
    contents.font.size = Revoked::Menu::FONT_MENULIST
    contents.font.color = Revoked::Menu::FONT_BROWN
    contents.font.outline = false
    contents.font.shadow = false
    if item
      draw_icon(item.icon_index, x, y+1, enabled)
      draw_text(x + 25, y, width, line_height, item.name)
    else
      contents.font.color.alpha = 128
      draw_text(x + 4, y, width, line_height, "------")
    end
  end

  alias rvkd_custom_sceq_window_equipslot_update_help update_help
  def update_help
    rvkd_custom_sceq_window_equipslot_update_help
    @attribute_window.set_temp_actor(nil) if @attribute_window
    p("called")
  end


end

#=============================================================================
# ■ Window_EquipItem
#-----------------------------------------------------------------------------
# Equipment item list.
#=============================================================================
class Window_EquipItem < Window_ItemList
  attr_reader :attribute_window

  alias rvkd_custom_sceq_window_equipitem_initialize initialize
  def initialize(x, y, width, height)
    rvkd_custom_sceq_window_equipitem_initialize(x, y, width, height)
    @panel = RvkdMenu_WindowPanel.new(self.x, self.y, 166, 114, @viewport, true)
    self.back_opacity = 0
  end

  def attribute_window=(attribute_window)
    @attribute_window = attribute_window
    call_update_help
  end

  def standard_padding ; 7 end
  def line_height ; 25 end
  def col_max ; 1 end

  #override: draw_item(index)
  def draw_item_name(item, x, y, enabled = true, width = 172)
    contents.font.size = Revoked::Menu::FONT_MENULIST
    contents.font.color = Revoked::Menu::FONT_LIGHT
    contents.font.outline = false
    contents.font.shadow = false
    if item
      draw_icon(item.icon_index, x, y+1, enabled)
      draw_text(x + 25, y, width, line_height, item.name)
    else
      contents.font.color.alpha = 128
      draw_text(x + 4, y, width, line_height, "------")
    end
  end

  alias rvkd_custom_sceq_window_equipitem_update_help update_help
  def update_help
    rvkd_custom_sceq_window_equipitem_update_help
    if @actor && @attribute_window
      temp_actor = Marshal.load(Marshal.dump(@actor))
      temp_actor.force_change_equip(@slot_id, item)
      @attribute_window.set_temp_actor(temp_actor)
    end
  end

end

#=============================================================================
# ■ Window_EquipStatus
#-----------------------------------------------------------------------------
# Equipment combat stat window (atk, def, spb, res, acc, eva, cri)
#=============================================================================
class Window_EquipStatus < Window_Base

  alias rvkd_custom_sceq_window_equipstatus_initialize initialize
  def initialize(x, y)
    rvkd_custom_sceq_window_equipstatus_initialize(x, y)
    if self.class == Window_EquipStatus
      @panel = RvkdMenu_WindowPanel.new(self.x, self.y, 166, 154, @viewport)
    end
    self.back_opacity = 0
  end

  def refresh
    contents.clear
    contents.font.size = Revoked::Menu::FONT_MENULIST
    contents.font.name = Revoked::Menu::FONT_NAME
    [2,4,3,5].each_with_index {|s,i| draw_param(0, line_height * i, s)}
    3.times {|i| draw_xparam(0, 4 + line_height * (i+4), i)}
  end

  def window_width ; 166 end
  def window_height ; 154 end
  def line_height ; 19 end
  def standard_padding ; 8 end

  # params: atk, def, spb, mdef
  def draw_param(x, y, param_id)
    draw_param_name(x + 4, y, param_id)
    draw_current_param(x + 80, y, param_id) if @actor
  end

  def draw_param_name(x, y, param_id)
    contents.font.color = Revoked::Menu::STAT_NAME_COLOR
    contents.font.shadow =  Revoked::Menu::STAT_NAME_SHADOW
    contents.font.outline = Revoked::Menu::STAT_NAME_OUTLINE
    draw_text(x, y, 80, line_height, Vocab::param(param_id))
  end

  def draw_current_param(x, y, param_id)
    contents.font.color = Revoked::Menu::STAT_VALUE_COLOR
    contents.font.shadow =  Revoked::Menu::STAT_VALUE_SHADOW
    contents.font.outline = Revoked::Menu::STAT_VALUE_OUTLINE
    cur = @actor.param(param_id)
    change = @temp_actor.param(param_id) if @temp_actor
    if change && cur != change
      icon_index = Revoked::Menu::Equip::ICON_UP if cur < change
      icon_index = Revoked::Menu::Equip::ICON_DOWN if cur > change
      draw_icon(icon_index, x + 24, y - 3)
      draw_text(x - 42, y, 64, line_height, "#{cur}", 2)
      change_color(param_change_color(change - cur))
      text = change
    else
      text = cur
    end
    contents.font.size = Revoked::Menu::FONT_MENULIST
    draw_text(x, y, 64, line_height, text, 2)
  end

  # xparams: accuracy, evasion, critical
  def draw_xparam(x, y, xparam_id)
    draw_xparam_name(x + 4, y, xparam_id)
    draw_current_xparam(x + 80, y, xparam_id) if @actor
  end

  def draw_xparam_name(x, y, xparam_id)
    contents.font.color = Revoked::Menu::STAT_NAME_COLOR
    contents.font.shadow =  Revoked::Menu::STAT_NAME_SHADOW
    contents.font.outline = Revoked::Menu::STAT_NAME_OUTLINE
    draw_text(x, y, 80, line_height, Vocab.xparam(xparam_id))
  end

  def draw_current_xparam(x, y, xparam_id)
    contents.font.color = Revoked::Menu::STAT_VALUE_COLOR
    contents.font.shadow =  Revoked::Menu::STAT_VALUE_SHADOW
    contents.font.outline = Revoked::Menu::STAT_VALUE_OUTLINE
    cur = (@actor.xparam(xparam_id)*100).to_i
    change = (@temp_actor.xparam(xparam_id)*100).to_i if @temp_actor
    if change && cur != change
      icon_index = Revoked::Menu::Equip::ICON_UP if cur < change
      icon_index = Revoked::Menu::Equip::ICON_DOWN if cur > change
      draw_icon(icon_index, x + 24, y - 2)
      draw_text(x - 42, y, 64, line_height, cur, 2)
      change_color(param_change_color(change - cur))
      text = change
    else
      text = cur
    end
    contents.font.size = Revoked::Menu::FONT_MENULIST
    draw_text(x, y, 64, line_height, text, 2)
  end

end

#=============================================================================
# ■ Window_EquipAttribute (new)
#-----------------------------------------------------------------------------
# Equipment attribute stat window (mgt, arc, vit, agi, res)
#=============================================================================
class Window_EquipAttribute < Window_EquipStatus

  def initialize(x, y)
    super(x, y)
    @panel = RvkdMenu_WindowPanel.new(self.x, self.y, 166, 114, @viewport)
    self.back_opacity = 0
  end

  def window_width ; 166 end
  def window_height ; 114 end
  def line_height ; 19 end

  def refresh
    contents.clear
    contents.font.size = Revoked::Menu::FONT_MENULIST
    contents.font.name = Revoked::Menu::FONT_NAME
    3.times {|i| draw_bparam(0, line_height * i + 2, i)}
    [6,7].each {|i| draw_param(0, line_height * (i-3) + 2, i)}
  end

  # bparams: might, arcana, vitality
  def draw_bparam(x, y, bparam_id)
    draw_bparam_name(x + 4, y, bparam_id)
    draw_current_bparam(x + 80, y, bparam_id) if @actor
  end

  def draw_bparam_name(x, y, bparam_id)
    contents.font.color = Revoked::Menu::STAT_NAME_COLOR
    # contents.font.size = Revoked::Menu::FONT_MENULIST
    # contents.font.name = Revoked::Menu::FONT_NAME
    contents.font.shadow =  Revoked::Menu::STAT_NAME_SHADOW
    contents.font.outline = Revoked::Menu::STAT_NAME_OUTLINE
    draw_text(x, y, 80, line_height, Vocab.bparam(bparam_id))
  end

  def draw_current_bparam(x, y, bparam_id)
    contents.font.color = Revoked::Menu::STAT_VALUE_COLOR
    # contents.font.size = Revoked::Menu::FONT_MENULIST
    # contents.font.name = Revoked::Menu::FONT_NAME
    contents.font.shadow =  Revoked::Menu::STAT_VALUE_SHADOW
    contents.font.outline = Revoked::Menu::STAT_VALUE_OUTLINE
    cur = @actor.bparam(bparam_id)
    change = @temp_actor.bparam(bparam_id) if @temp_actor
    if change && cur != change
      w = text_size(change).width + 20
      icon_index = Revoked::Menu::Equip::ICON_UP if cur < change
      icon_index = Revoked::Menu::Equip::ICON_DOWN if cur > change
      draw_icon(icon_index, x + 24, y - 2)
      draw_text(x - 42, y, 64, line_height, cur, 2)
      change_color(param_change_color(change - cur))
      text = change
    else
      text = cur
    end
    draw_text(x, y, 64, line_height, text, 2)
  end

end

#=============================================================================
# ■ Window_EquipPreview (new)
#-----------------------------------------------------------------------------
# Equipment character preview (element symbols)
#=============================================================================
class Window_EquipPreview < Window_Base

  def initialize(x,y)
    super(x, y, window_width, window_height)
    @panel = RvkdMenu_WindowPanel.new(self.x, self.y, 166, 154, @viewport)
    @actor = nil
    @character_sprite = nil
    self.back_opacity = 0
    make_platform
  end

  def window_width ; 166 end
  def window_height ; 154 end
  def standard_padding ; 3 end
  def translucent_alpha ; 128 end

  def actor=(actor)
    return if @actor == actor
    @actor = actor
    refresh
  end

  alias rvkd_custom_sceq_window_equippreview_dispose dispose
  def dispose
    rvkd_custom_sceq_window_equippreview_dispose
    @character_sprite.dispose if @character_sprite
    @platform.dispose if @platform
  end

  def refresh
    contents.clear
    draw_element_icons(@actor)
    update_actor_sprite
  end

  def make_platform
    @platform = Sprite.new(@viewport)
    @platform.bitmap = Cache.menus("preview_diamond")
    @platform.x = self.x
    @platform.y = self.y
    @platform.z = 92
  end

  def update_actor_sprite
    # check counter
  end

  def draw_element_icons(actor)
    8.times do |index|
      icon_x = Revoked::Menu::Equip::ELEM_POS[index][0]
      icon_y = Revoked::Menu::Equip::ELEM_POS[index][1]
      icon_index = Revoked::Menu::Equip::ELEM_ICONS[index]
      element_rate = Revoked::Menu::Equip::ELEM_ID[index]
      modified = actor.element_rate(element_rate) != 1.0
      draw_icon(icon_index, icon_x, icon_y, modified)
    end
  end

end

#=============================================================================
# ■ Window_EquipCharacter (new)
#-----------------------------------------------------------------------------
# Equipment character resources window (hp, mp, zp)
#=============================================================================
class Window_EquipCharacter < Window_Base

  def initialize(x,y)
    super(x, y, window_width, window_height)
    @panel = RvkdMenu_WindowPanel.new(self.x, self.y, 198, 70, @viewport)
    @actor = nil
    @character_card = nil
    self.back_opacity = 0
  end

  def window_width ; 198 end
  def window_height ; 70 end
  def standard_padding ; 3 end

  def actor=(actor)
    return if @actor == actor
    @actor = actor
    refresh
  end

  def refresh
    contents.clear
    if @character_card
      @character_card.refresh
    else
      cc = RvkdEquip_CharacterCard.new(@viewport,@actor,self.x,self.y)
      @character_card = cc
    end
    draw_status if @actor
  end

  def dispose_sprites
    @character_card.dispose
  end

  def draw_status
    bar_x = Revoked::Menu::Equip::HP_BAR[:bar_x]
    draw_actor_hp(bar_x, Revoked::Menu::Equip::HP_BAR[:bar_y])
    draw_actor_mp(bar_x, Revoked::Menu::Equip::MP_BAR[:bar_y])
    draw_actor_face(@actor, 0, 0)
  end

  def draw_actor_hp(x,y,width = Revoked::Menu::STATUS[:bar_width])
    self.z = 800
    contents.font.outline = true
    contents.font.size = Revoked::Menu::FONT_SMALL
    contents.font.name = Revoked::Menu::FONT_NAME
    contents.font.color = hp_color(@actor)
    text_x = Revoked::Menu::Equip::HP_BAR[:text_x]
    text_y = Revoked::Menu::Equip::HP_BAR[:text_y]
    draw_text(x + text_x, text_y, width, line_height, "#{@actor.hp}", 2)
  end

  def draw_actor_mp(x,y,width = Revoked::Menu::STATUS[:bar_width])
    self.z = 800
    contents.font.outline = true
    contents.font.size = Revoked::Menu::FONT_SMALL
    contents.font.name = Revoked::Menu::FONT_NAME
    contents.font.color = mp_color(@actor)
    text_x = Revoked::Menu::Equip::MP_BAR[:text_x]
    text_y = Revoked::Menu::Equip::MP_BAR[:text_y]
    draw_text(x + text_x, text_y, width, line_height, "#{@actor.mp}", 2)
  end

  #override: draw_face (to stretch)
  def draw_face(face_name, face_index, x, y, enabled = true)
    face_name = Revoked::Menu::Equip::FACE_NAME
    bitmap = Cache.face(face_name)
    rect = Rect.new(face_index % 4 * 96, face_index / 4 * 96, 96, 96)
    #drect = Rect.new(0, 0, 64, 64)
    contents.blt(x,y, bitmap, rect, enabled ? 255 : translucent_alpha)
    bitmap.dispose
  end

end


#=============================================================================
# ■ RvkdEquip_CharacterCard (new)
#-----------------------------------------------------------------------------
# Equipment menu character card
#=============================================================================
class RvkdEquip_CharacterCard < Sprite

  def initialize(viewport,actor,x,y)
    super(viewport)
    self.x = x
    self.y = y
    @actor = actor
    make_sprites
  end

  def actor=(actor)
    return if @actor == actor
    @actor = actor
    refresh
  end

  def refresh
    clear_sprites
    make_sprites
  end

  def make_hp
    @hp_bar = Sprite.new(@viewport)
    @hp_bar.bitmap = Cache.menus("Menu_HPBar")
    @hp_bar.x = self.x + Revoked::Menu::Equip::HP_BAR[:bar_x]
    @hp_bar.y = self.y + Revoked::Menu::Equip::HP_BAR[:bar_y]
    @hp_bar.z = 120

    @hp_diamond = Sprite.new(@viewport)
    @hp_diamond.bitmap = Cache.menus("Menu_HPDiamond")
    @hp_diamond.x = self.x + Revoked::Menu::Equip::HP_BAR[:diam_x]
    @hp_diamond.y = self.y + Revoked::Menu::Equip::HP_BAR[:diam_y]
    @hp_diamond.z = 122

    @hp_fill = RvkdMenu_StatBar.new(@viewport, :hp, @actor)
    @hp_fill.bitmap = Cache.menus("Menu_HPFill")
    @hp_fill.x = self.x + Revoked::Menu::Equip::HP_BAR[:fill_x]
    @hp_fill.y = self.y + Revoked::Menu::Equip::HP_BAR[:fill_y]
    @hp_fill.z = 121
  end

  def make_mp
    @mp_bar = Sprite.new(@viewport)
    @mp_bar.bitmap = Cache.menus("Menu_MPBar")
    @mp_bar.x = self.x + Revoked::Menu::Equip::MP_BAR[:bar_x]
    @mp_bar.y = self.y + Revoked::Menu::Equip::MP_BAR[:bar_y]
    @mp_bar.z = 120

    @mp_diamond = Sprite.new(@viewport)
    @mp_diamond.bitmap = Cache.menus("Menu_MPDiamond")
    @mp_diamond.x = self.x + Revoked::Menu::Equip::MP_BAR[:diam_x]
    @mp_diamond.y = self.y + Revoked::Menu::Equip::MP_BAR[:diam_y]
    @mp_diamond.z = 122

    @mp_fill = RvkdMenu_StatBar.new(@viewport, :mp, @actor)
    @mp_fill.bitmap = Cache.menus("Menu_MPFill")
    @mp_fill.x = self.x + Revoked::Menu::Equip::MP_BAR[:fill_x]
    @mp_fill.y = self.y + Revoked::Menu::Equip::MP_BAR[:fill_y]
    @mp_fill.z = 121
  end

  def make_tp
    @tp_diamonds = []
    max_tp = @actor.max_tp
    cur_tp = @actor.tp_rise

    b_x = Revoked::Menu::Equip::TP_BAR[:ary_x]
    d_x = Revoked::Menu::Equip::TP_BAR[:offset_x]

    max_tp.times do |i|
      frame = Sprite.new(@viewport)
      frame.bitmap = Cache.menus("Menu_ZP_#{i >= cur_tp ? "Empty" : "Full"}")
      frame.x = self.x + i * d_x + b_x
      frame.y = self.y + Revoked::Menu::Equip::TP_BAR[:ary_y]
      frame.z = 222
      @tp_diamonds.push(frame)
    end
  end

  alias rvkd_custom_sceq_sprite_dispose dispose
  def dispose
    clear_sprites
    rvkd_custom_sceq_sprite_dispose
  end

  def make_sprites
    make_hp
    make_mp
    make_tp
  end

  def clear_sprites
    @hp_bar.dispose
    @hp_fill.dispose
    @hp_diamond.dispose
    @mp_bar.dispose
    @mp_fill.dispose
    @mp_diamond.dispose
    @tp_diamonds.each {|diamond| diamond.dispose}
  end

end

#=============================================================================
# ■ RvkdMenu_WindowPanel (new)
#-----------------------------------------------------------------------------
# Menu background panels.
#=============================================================================
class RvkdMenu_WindowPanel < Sprite

  def initialize(x, y, width, height, viewport, lines = false)
    @background = Sprite.new(viewport)
    @background.x = x
    @background.y = y
    @background.z = 90
    @background.bitmap = Cache.menus("Win_#{width}x#{height}")
    if lines
      @lines = Sprite.new(viewport)
      @lines.x = x
      @lines.y = y
      @lines.z = 96
      @lines.bitmap = Cache.menus("Lin_#{width}x#{height}")
    end
  end

  alias rvkd_custom_window_panel_sprite_dispose dispose
  def dispose
    clear_sprites
    rvkd_custom_window_panel_sprite_dispose
  end

  def clear_sprites
    @background.dispose
    @lines.dispose if @lines
  end

end
