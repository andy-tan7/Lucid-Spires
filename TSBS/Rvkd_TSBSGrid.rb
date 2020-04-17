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

  def grid_size
    return @grid_size if @grid_size
    if $data_enemies[self.enemy_id].note =~ /<grid[\s_]*size:[\s]*(\d+)>/i
      case $1.to_i
      when 1 ; @grid_size = 1
      when 2 ; @grid_size = 2
      when 4 ; @grid_size = 4
      else ; @grid_size = 1
      end
    end
    return @grid_size
  end

  def offset_x ; return @offset_x + Revoked::Grid::UnitXOffset ; end
  def offset_y ; return @offset_y + Revoked::Grid::UnitYOffset ; end

end

class RPG::Troop::Member
  def x ; return @x + Revoked::Grid::UnitXOffset ; end
  def y ; return @y + Revoked::Grid::UnitYOffset ; end
end

class Game_Enemy < Game_Battler
  # def screen_x
  #   @screen_x + Revoked::Grid::UnitXOffset
  # end
  # def screen_y
  #   @screen_y + Revoked::Grid::UnitYOffset
  # end

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
