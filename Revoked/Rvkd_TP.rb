#===========================================================================
# ** Revoked Custom TP values
#---------------------------------------------------------------------------
#  This script modifies various values for TP.
#     - TP values are now single-digits (0-10 instead of 0-100)
#     - TP gain for using abilities (defined in db) divided by 100
#     - TP gain for taking damage now defined as 1 TP per 50% MaxHP lost.
#
#     - Battlers can achieve higher TP caps (exceed) and can acquire an
#       initial value for TP in battle (rise).
#===========================================================================
module Revoked
  module Actor

    BASE_TP = 3
    MAX_TP = 8

  end
end

class Game_BattlerBase

  #alias: initialize
  alias rvkd_tp_ga_initialize initialize
  def initialize
    rvkd_tp_ga_initialize
    make_tp_attrs
  end

  attr_accessor :tp_exceed
  attr_accessor :tp_rise

  def make_tp_attrs
    @base_tp = nil
    @tp_exceed = 0
    @tp_rise = 0
  end

  def base_mtp
    return @base_tp if @base_tp

    if self.is_a?(Game_Actor)
      @base_tp = $1.to_i if self.actor.note =~ /<base_tp:[ ](\d+)>/i
    elsif self.is_a?(Game_Enemy)
      @base_tp = $1.to_i if self.enemy.note =~ /<base_tp:[ ](\d+)>/i
    end

    @base_tp ||= Revoked::Actor::BASE_TP
  end

  def display_current_tp
    @tp_rise
  end

end

class Game_Battler < Game_BattlerBase

  #alias: on_battle_end
  alias rvkd_tp_gb_on_battle_end on_battle_end
  def on_battle_end
    rvkd_tp_gb_on_battle_end
    init_tp
  end

  #overwrite: init_tp
  def init_tp
    self.tp = @tp_rise
  end

  #overwrite: item_user_effect
  def item_user_effect(user, item)
    user.tp += item.tp_gain * user.tcr / 100 #db values fractional
  end

  #overwrite: charge_tp_by_damage
  def charge_tp_by_damage(damage_rate)
    self.tp += 2 * damage_rate * tcr  # 50% hp damage per 1 TP
  end

end

class Game_Actor < Game_Battler

    #overwrite: max tp
    def max_tp
      val = base_mtp + @tp_exceed rescue Revoked::Actor::BASE_TP
      return [val, Revoked::Actor::MAX_TP].min
    end

    #overwrite: tp_rate
    def tp_rate
      return @tp / max_tp
    end

end

# class RPG::Actor < RPG::BaseItem
#
#   attr_reader :base_mtp
#   # #alias: initialize
#   # alias rvkd_tp_rpg_actor_initialize initialize
#   # def initialize
#   #   rvkd_tp_rpg_actor_initialize
#   # end
#
#   def make_base_tp
#     @base_mtp = Revoked::Actor::BASE_TP
#     if self.note =~ /<tp:[ ](\d+)>/i
#       @base_mtp = $1.to_i
#     end
#   end
#
# end

# class RPG::Enemy < RPG::BaseItem
#
#   attr_reader :base_mtp
#   def make_base_tp
#     @base_mtp = Revoked::Actor::BASE_TP
#     if self.note =~ /<tp:[ ](\d+)>/i
#       @base_mtp = $1.to_i
#     end
#   end
#
# end

# class << DataManager
#
#   alias rvkd_tp_load_db load_database
#   def load_database
#     rvkd_tp_load_db
#     load_tp
#   end
#
#   def load_tp
#     ($data_actors + $data_enemies).compact.each {|item| item.make_base_tp }
#   end
#
# end
