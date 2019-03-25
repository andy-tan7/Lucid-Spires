
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
    STAT_NAME_COLOR = FONT_LIGHT
    STAT_NAME_SHADOW = false
    STAT_NAME_OUTLINE = false

    STAT_VALUE_COLOR = Color.new(255,255,255,255)
    STAT_VALUE_SHADOW = false
    STAT_VALUE_OUTLINE = true

    module Equip
      HP_BAR = {:bar_x  => 74, :bar_y  => 18, #EquipCharacter card
                :fill_x => 75, :fill_y => 19,
                :diam_x => 76, :diam_y => 7,
                :text_x => 6,  :text_y => 5}

      MP_BAR = {:bar_x  => 74, :bar_y  => 37, #EquipCharacter card
                :fill_x => 75, :fill_y => 38,
                :diam_x => 76, :diam_y => 26,
                :text_x => 6,  :text_y => 24}

      TP_BAR = {:ary_x => 74, :ary_y => 49, :offset_x => 14}
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
    @command_window.x = 0
    @command_window.y = 0
  end

  alias rvkd_custom_sceq_command_clear command_clear
  def command_clear
    rvkd_custom_sceq_command_clear
    @attribute_window.refresh
    @character_window.refresh
  end

  alias rvkd_custom_sceq_command_optimize command_optimize
  def command_optimize
    rvkd_custom_sceq_command_optimize
    @attribute_window.refresh
    @character_window.refresh
  end

  alias rvkd_custom_sceq_on_item_ok on_item_ok
  def on_item_ok
    rvkd_custom_sceq_on_item_ok
    @attribute_window.refresh
    @character_window.refresh
  end

  alias rvkd_custom_sceq_on_actor_change on_actor_change
  def on_actor_change
    @attribute_window.actor = @actor
    @character_window.actor = @actor
    rvkd_custom_sceq_on_actor_change
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
  end

  #new: create_character_window
  def create_character_window
    @character_window = Window_EquipCharacter.new(48, 64)
    @character_window.viewport = @viewport
    @character_window.actor = @actor
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
  end

  #overwrite: create_item_window
  def create_item_window
    @item_window = Window_EquipItem.new(256,228,166,114)
    @item_window.viewport = @viewport
    @item_window.help_window = @help_window
    @item_window.status_window = @status_window
    @item_window.attribute_window = @attribute_window
    @item_window.actor = @actor
    @item_window.set_handler(:ok,     method(:on_item_ok))
    @item_window.set_handler(:cancel, method(:on_item_cancel))
    @slot_window.item_window = @item_window
  end

end

#=============================================================================
# ■ Window_EquipSlot
#-----------------------------------------------------------------------------
# Equipment slot window.
#=============================================================================
class Window_EquipSlot < Window_Selectable
  attr_reader :attribute_window

  def attribute_window=(attribute_window)
    @attribute_window = attribute_window
  end

  def window_height ; 198 end

  alias rvkd_custom_sceq_window_equipslot_draw_item draw_item
  def draw_item(index)
    contents.font.size = Revoked::Menu::FONT_MENULIST
    contents.font.name = Revoked::Menu::FONT_NAME
    rvkd_custom_sceq_window_equipslot_draw_item(index)
  end
end

#=============================================================================
# ■ Window_EquipItem
#-----------------------------------------------------------------------------
# Equipment item list.
#=============================================================================
class Window_EquipItem < Window_ItemList
  attr_reader :attribute_window

  def attribute_window=(attribute_window)
    @attribute_window = attribute_window
  end
end

#=============================================================================
# ■ Window_EquipStatus
#-----------------------------------------------------------------------------
# Equipment combat stat window (atk, def, spb, res, acc, eva, cri)
#=============================================================================
class Window_EquipStatus < Window_Base
  def refresh
    contents.clear
    contents.font.size = Revoked::Menu::FONT_MENULIST
    contents.font.name = Revoked::Menu::FONT_NAME
    [2,3].each {|i| draw_param(0, line_height * (i-2), i)}
    [4,5].each {|i| draw_param(0, line_height * (i-2), i)}
    3.times {|i| draw_xparam(0, 4 + line_height * (i+4), i)}
  end

  def window_width ; 166 end
  def window_height ; 154 end
  def line_height ; 19 end
  def standard_padding ; 8 end

  # params: atk, def, spb, mdef
  def draw_param(x, y, param_id)
    draw_param_name(x + 4, y, param_id)
    draw_current_param(x + 112, y, param_id) if @actor
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
    draw_text(x, y, 32, line_height, @actor.param(param_id), 2)
  end

  # xparams: accuracy, evasion, critical
  def draw_xparam(x, y, xparam_id)
    draw_xparam_name(x + 4, y, xparam_id)
    draw_current_xparam(x + 112, y, xparam_id) if @actor
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
    draw_text(x, y, 32, line_height, "#{(@actor.xparam(xparam_id)*100).to_i}",2)
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
    draw_current_bparam(x + 112, y, bparam_id) if @actor
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
    draw_text(x, y, 32, line_height, @actor.bparam(bparam_id), 2)
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
    @actor = nil
    @character_card = nil
  end

  def window_width ; 198 end
  def window_height ; 70 end

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
      @character_card = RvkdEquip_CharacterCard.new(@viewport,@actor,self.x,self.y)
    end
  end

end

class RvkdEquip_CharacterCard < Sprite

  def initialize(viewport,actor,x,y)
    super(viewport)
    self.x = x
    self.y = y
    @actor = actor
    make_hp
    make_mp
    make_tp
  end

  def refresh
    clear_sprites
    make_hp
    make_mp
    make_tp
  end

  def make_hp
    @hp_bar = Sprite.new(@viewport)
    @hp_bar.bitmap = Cache.menus("Menu_HPBar")
    @hp_bar.x = self.x + Revoked::Menu::Equip::HP_BAR[:bar_x]
    @hp_bar.y = self.y + Revoked::Menu::Equip::HP_BAR[:bar_y]
    @hp_bar.z = 220

    @hp_diamond = Sprite.new(@viewport)
    @hp_diamond.bitmap = Cache.menus("Menu_HPDiamond")
    @hp_diamond.x = self.x + Revoked::Menu::Equip::HP_BAR[:diam_x]
    @hp_diamond.y = self.y + Revoked::Menu::Equip::HP_BAR[:diam_y]
    @hp_diamond.z = 222

    @hp_fill = RvkdMenu_StatBar.new(@viewport, :hp, @actor)
    @hp_fill.bitmap = Cache.menus("Menu_HPFill")
    @hp_fill.x = self.x + Revoked::Menu::Equip::HP_BAR[:fill_x]
    @hp_fill.y = self.y + Revoked::Menu::Equip::HP_BAR[:fill_y]
    @hp_fill.z = 221
  end

  def make_mp
    @mp_bar = Sprite.new(@viewport)
    @mp_bar.bitmap = Cache.menus("Menu_MPBar")
    @mp_bar.x = self.x + Revoked::Menu::Equip::MP_BAR[:bar_x]
    @mp_bar.y = self.y + Revoked::Menu::Equip::MP_BAR[:bar_y]
    @mp_bar.z = 220

    @mp_diamond = Sprite.new(@viewport)
    @mp_diamond.bitmap = Cache.menus("Menu_MPDiamond")
    @mp_diamond.x = self.x + Revoked::Menu::Equip::MP_BAR[:diam_x]
    @mp_diamond.y = self.y + Revoked::Menu::Equip::MP_BAR[:diam_y]
    @mp_diamond.z = 222

    @mp_fill = RvkdMenu_StatBar.new(@viewport, :mp, @actor)
    @mp_fill.bitmap = Cache.menus("Menu_MPFill")
    @mp_fill.x = self.x + Revoked::Menu::Equip::MP_BAR[:fill_x]
    @mp_fill.y = self.y + Revoked::Menu::Equip::MP_BAR[:fill_y]
    @mp_fill.z = 221
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
