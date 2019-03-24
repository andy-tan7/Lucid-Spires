
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


  end
end


class Scene_Equip < Scene_MenuBase

  alias rvkd_custom_sceq_start start
  def start
    rvkd_custom_sceq_start
    create_attribute_window
    @command_window.x = 0
    @command_window.y = 0
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
    #48, 144
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

class Window_EquipSlot < Window_Selectable
  attr_reader :attribute_window

  def attribute_window=(attribute_window)
    @attribute_window = attribute_window
  end
end

class Window_EquipItem < Window_ItemList
  attr_reader :attribute_window

  def attribute_window=(attribute_window)
    @attribute_window = attribute_window
  end
end

class Window_EquipSlot < Window_Selectable
  def window_height ; 198 end

  alias rvkd_custom_sceq_window_equipslot_draw_item draw_item
  def draw_item(index)
    contents.font.size = Revoked::Menu::FONT_SMALL
    contents.font.name = Revoked::Menu::FONT_NAME
    rvkd_custom_sceq_window_equipslot_draw_item(index)
  end
end

class Window_EquipStatus < Window_Base
  def refresh
    contents.clear
    contents.font.size = Revoked::Menu::FONT_SMALL
    contents.font.name = Revoked::Menu::FONT_NAME
    contents.font.outline = true
    [2,4,3,5].each {|i| draw_param(0, line_height * (i-2), i)}
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

  # xparams: accuracy, evasion, critical
  def draw_xparam(x, y, xparam_id)
    draw_xparam_name(x + 4, y, xparam_id)
    draw_current_xparam(x + 112, y, xparam_id) if @actor
  end

  def draw_xparam_name(x, y, xparam_id)
    change_color(system_color)
    draw_text(x, y, 80, line_height, Vocab.xparam(xparam_id))
  end

  def draw_current_xparam(x, y, xparam_id)
    change_color(normal_color)
    draw_text(x, y, 32, line_height, @actor.xparam(xparam_id), 2)
  end

end

class Window_EquipAttribute < Window_EquipStatus

  def initialize(x, y)
    super(x, y)
  end

  def window_width ; 166 end
  def window_height ; 114 end
  def line_height ; 19 end

  def refresh
    contents.clear
    3.times {|i| draw_bparam(0, line_height * i, i)}
    [6,7].each {|i| draw_param(0, line_height * (i-3), i)}
  end

  # bparams: might, arcana, vitality
  def draw_bparam(x, y, bparam_id)
    draw_bparam_name(x + 4, y, bparam_id)
    draw_current_bparam(x + 112, y, bparam_id) if @actor
  end

  def draw_bparam_name(x, y, bparam_id)
    change_color(system_color)
    contents.font.size = Revoked::Menu::FONT_SMALL
    contents.font.name = Revoked::Menu::FONT_NAME
    contents.font.outline = true
    draw_text(x, y, 80, line_height, Vocab.bparam(bparam_id))
  end

  def draw_current_bparam(x, y, bparam_id)
    change_color(normal_color)
    contents.font.size = Revoked::Menu::FONT_SMALL
    contents.font.name = Revoked::Menu::FONT_NAME
    contents.font.outline = true
    draw_text(x, y, 32, line_height, @actor.bparam(bparam_id), 2)
  end

end
