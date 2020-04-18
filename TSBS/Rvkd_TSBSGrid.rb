# Place below TSBS scripts.

# Set up the actor's grid positions at the start of battle.
class Game_Actor
  alias rvkd_grid_tsbs_ga_init_oripost init_oripost
  def init_oripost
    set_grid_coordinates(*($game_party.grid_positions[id]))
    rvkd_grid_tsbs_ga_init_oripost
  end
end

#------------------------------------------------------------------------------
# Use a different shadow image size based on the size of the unit if specified.
# This is done to avoid pixellated shadows from rescaling one image.
class Sprite_BattlerShadow < Sprite
  #override
  def update_shadow
    if data_battler
      if !@sprite_battler.battler.enemy?
        @shadow_name = @sprite_battler.battler.data_battler.custom_shadow
      else
        @shadow_name = @sprite_battler.battler.shadow_name
      end
      self.bitmap = Cache.system(@shadow_name)
    end
  end
end


class Game_Enemy < Game_Battler

  def shadow_name
    return @shadow_name if @shadow_name
    if $data_enemies[self.enemy_id].note =~ /<shadow[\s_]*size:[\s]*(\w+)>/i
      case $1
      when /SMALL/i  ; @shadow_name = "Shadow_Small"
      when /MEDIUM/i ; @shadow_name = "Shadow_Medium"
      when /LARGE/i  ; @shadow_name = "Shadow_Large"
      end
    else
      @shadow_name = "Shadow_Small"
    end
    return @shadow_name
  end
end

class << BattleManager
  alias rvkd_tsbs_shadow_btm_setup setup
  def setup(troop_id, can_escape = true, can_lose = false)
    rvkd_tsbs_shadow_btm_setup(troop_id)
    $game_troop.members.each {|member| member.shadow_name }
  end
end
