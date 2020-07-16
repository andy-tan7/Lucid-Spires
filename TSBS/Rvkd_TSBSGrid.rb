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

class Game_Battler < Game_BattlerBase
  #
  #alias rvkd_grid_tsbs_gb_setup_reset setup_reset
  def setup_reset
    p("! ------ Resetting ----------")
    p(@ori_x, @ori_y)
    @ori_x = self.original_x
    @ori_y = self.original_y
    p(@ori_x, @ori_y)
    stop_all_movements
    goto(@ori_x, @ori_y, @acts[1], @acts[2])
    #rvkd_grid_tsbs_gb_setup_reset
  end

  def original_x
    len = grid_coordinates.size
    avg_r = grid_coordinates.collect{|p| p[0]}.inject{|s,r| s + r}.to_f / len
    avg_c = grid_coordinates.collect{|p| p[1]}.inject{|s,c| s + c}.to_f / len
    unit_x = Revoked::Grid.position(avg_r, avg_c)[:x]
    unit_x += Revoked::Grid::UnitXOffset
    return unit_x
  end

  def original_y
    len = grid_coordinates.size
    avg_r = grid_coordinates.collect{|p| p[0]}.inject{|s,r| s + r}.to_f / len
    avg_c = grid_coordinates.collect{|p| p[1]}.inject{|s,c| s + c}.to_f / len
    unit_y = Revoked::Grid.position(avg_r, avg_c)[:y]
    unit_y += Revoked::Grid::UnitYOffset
    return unit_y
  end
end

class Game_Actor < Game_Battler
  #override
  def original_x
    unit_x = Revoked::Grid.position(grid_row, grid_col)[:x]
    unit_x += Revoked::Grid::UnitXOffset
    return unit_x
  end
  #override
  def original_y
    unit_y = Revoked::Grid.position(grid_row, grid_col)[:y]
    unit_y += Revoked::Grid::UnitYOffset
    return unit_y
  end
end

class Game_Enemy < Game_Battler

  # def original_x
  # end
  # def original_y
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
