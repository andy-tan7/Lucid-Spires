#===========================================================================
# ** Revoked Custom Stats
#---------------------------------------------------------------------------
#  This script provides support for additional bparams (bonus params).
#===========================================================================
class Game_BattlerBase

  FEATURE_BPARAM = 24  # Bonus Parameter, custom

  # Access by bparameter abbreviations
  def mig;  bparam(0);  end
  def arc;  bparam(1);  end
  def vit;  bparam(2);  end

  def bparam_base(bparam_id)
    return 0
  end

  def bparam_plus(bparam_id)
    return 0#@bparam_plus[bparam_id]
  end

  def bparam_min(bparam_id)
    return 1
  end

  def bparam_max(bparam_id)
    return 99
  end

  def bparam_rate(bparam_id)
    features_pi(FEATURE_BPARAM, bparam_id)
  end

  def bparam_buff_rate(bparam_id)
    # todo
    # @buffs[param_id] * 0.25 + 1.0
    return 1.0
  end

  def bparam(bparam_id)
    value = bparam_base(bparam_id) + bparam_plus(bparam_id)
    value *= bparam_rate(bparam_id) + bparam_buff_rate(bparam_id)
    [[value, bparam_max(bparam_id)].min, bparam_min(bparam_id)].max.to_i
  end

end

class Game_Actor < Game_Battler

  def bparam_base(bparam_id)
    self.actor.base_bparam[bparam_id] + bparam_growth(bparam_id, level).floor
  end

  def bparam_growth(bparam_id, level)
    self.actor.growth_bparam[bparam_id] * level
  end
end


class << DataManager
  alias rvkd_custom_stats_load_db load_database
  def load_database
    rvkd_custom_stats_load_db
    load_custom_stats
  end

  def load_custom_stats
    ($data_actors).compact.each do |item|
      item.load_bparam_notetags
    end
  end
end


class RPG::Actor < RPG::BaseItem
  attr_reader :base_bparam
  attr_reader :growth_bparam

  # alias rvkd_custom_stats_rpg_actor_initialize initialize
  # def initialize
  #   rvkd_custom_stats_rpg_actor_initialize
  #   load_bparam_notetags
  # end

  def load_bparam_notetags
    @base_bparam = [5] * 3
    @growth_bparam = [0.4] * 3
    self.note.split(/[\r\n]+/).each do |line|
      if line =~ /<base[ _]bparams[:?]\s*(\d+),?[\s?](\d+),?[\s?](\d+)>/i
        @base_bparam[0] = $1.to_i
        @base_bparam[1] = $2.to_i
        @base_bparam[2] = $3.to_i
      end
      if line =~ /<growth[ _]bparams[:?]\s*(\d+),?[\s?](\d+),?[\s?](\d+)>/i
        @growth_bparam[0] = $1.to_i
        @growth_bparam[1] = $2.to_i
        @growth_bparam[2] = $3.to_i
      end
    end
    puts(2)
    puts(@base_param)
    puts(@growth_param)
  end

end

# class Game_BattlerBase
#
#   #overwrite: changed max from 8 to 11.
#   def clear_param_plus
#     @param_plus = [0] * 11
#   end
#
#   #overwrite: changed max from 8 to 11.
#   def clear_buffs
#     @buffs = Array.new(11) { 0 }
#     @buff_turns = {}
#   end
#
# end

# class RPG::Class < RPG::BaseItem
#   alias rvkd_custom_stats_rpg_class_initialize initialize
#   def initialize
#     rvkd_custom_stats_rpg_class_initialize
#     @params.resize(11)
#     (1..99).each do |i|
#       (8..11).each {|j| @params[j,i] = 15+i*5/4 }
#     end
#   end
#
# end
#
#
# class RPG::EquipItem < RPG::BaseItem
#   alias rvkd_custom_stats_rpg_equip_item_initialize initialize
#   def initialize
#     rvkd_custom_stats_rpg_equip_item_initialize
#     @params = [0] * 11
#   end
# end
