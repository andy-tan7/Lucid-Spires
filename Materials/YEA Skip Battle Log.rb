#==============================================================================
# ?  Skip Battle Log 1.0
# -- Last Updated: 2012.08.02
# -- Author: Yanfly, extracted by Helladen
#==============================================================================
# This allows you to skip some annoying messages while in battle.
#==============================================================================

module YEA
  module BATTLE
  #=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
  # - Streamlined Messages -
  #=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
  # Want to remove some of those annoying messages that appear all the time?
  # Now you can! Select which messages you want to enable or disable. Some of
  # these messages will be rendered useless due to popups.
  #=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
  MSG_ENEMY_APPEARS  = false  # Message when enemy appears start of battle.
  MSG_CURRENT_STATE  = false  # Show which states has affected battler.
  MSG_CURRENT_ACTION = false   # Show the current action of the battler.
  MSG_COUNTERATTACK  = false   # Show the message for a counterattack.
  MSG_REFLECT_MAGIC  = false   # Show message for reflecting magic attacks.
  MSG_SUBSTITUTE_HIT = false   # Show message for ally taking another's hit.
  MSG_FAILURE_HIT    = false  # Show effect failed against target.
  MSG_CRITICAL_HIT   = false  # Show attack was a critical hit.
  MSG_HIT_MISSED     = false  # Show attack missed the target.
  MSG_EVASION        = false  # Show attack was evaded by the target.
  MSG_HP_DAMAGE      = false  # Show HP damage to target.
  MSG_MP_DAMAGE      = false  # Show MP damage to target.
  MSG_TP_DAMAGE      = false  # Show TP damage to target.
  MSG_ADDED_STATES   = false  # Show target's added states.
  MSG_REMOVED_STATES = false  # Show target's removed states.
  MSG_CHANGED_BUFFS  = false  # Show target's changed buffs.
  end
end

#==============================================================================
# ¦ BattleManager
#==============================================================================
module BattleManager
  #--------------------------------------------------------------------------
  # overwrite method: self.battle_start
  #--------------------------------------------------------------------------
  def self.battle_start
    $game_system.battle_count += 1
    $game_party.on_battle_start
    $game_troop.on_battle_start
    return unless YEA::BATTLE::MSG_ENEMY_APPEARS
    $game_troop.enemy_names.each do |name|
      $game_message.add(sprintf(Vocab::Emerge, name))
    end
    if @preemptive
      $game_message.add(sprintf(Vocab::Preemptive, $game_party.name))
    elsif @surprise
      $game_message.add(sprintf(Vocab::Surprise, $game_party.name))
    end
    wait_for_message
  end

end

#==============================================================================
# ¦ Window_BattleLog
#==============================================================================
class Window_BattleLog < Window_Selectable
  #--------------------------------------------------------------------------
  # alias method: display_current_state
  #--------------------------------------------------------------------------
  alias window_battlelog_display_current_state_abe display_current_state
  def display_current_state(subject)
    return unless YEA::BATTLE::MSG_CURRENT_STATE
    window_battlelog_display_current_state_abe(subject)
  end

  #--------------------------------------------------------------------------
  # alias method: display_use_item
  #--------------------------------------------------------------------------
  alias window_battlelog_display_use_item_abe display_use_item
  def display_use_item(subject, item)
    return unless YEA::BATTLE::MSG_CURRENT_ACTION
    window_battlelog_display_use_item_abe(subject, item)
  end

  #--------------------------------------------------------------------------
  # alias method: display_counter
  #--------------------------------------------------------------------------
  alias window_battlelog_display_counter_abe display_counter
  def display_counter(target, item)
    if YEA::BATTLE::MSG_COUNTERATTACK
      window_battlelog_display_counter_abe(target, item)
    else
      Sound.play_evasion
    end
  end

  #--------------------------------------------------------------------------
  # alias method: display_reflection
  #--------------------------------------------------------------------------
  alias window_battlelog_display_reflection_abe display_reflection
  def display_reflection(target, item)
    if YEA::BATTLE::MSG_REFLECT_MAGIC
      window_battlelog_display_reflection_abe(target, item)
    else
      Sound.play_reflection
    end
  end

  #--------------------------------------------------------------------------
  # alias method: display_substitute
  #--------------------------------------------------------------------------
  alias window_battlelog_display_substitute_abe display_substitute
  def display_substitute(substitute, target)
    return unless YEA::BATTLE::MSG_SUBSTITUTE_HIT
    window_battlelog_display_substitute_abe(substitute, target)
  end

  #--------------------------------------------------------------------------
  # alias method: display_failure
  #--------------------------------------------------------------------------
  alias window_battlelog_display_failure_abe display_failure
  def display_failure(target, item)
    return unless YEA::BATTLE::MSG_FAILURE_HIT
    window_battlelog_display_failure_abe(target, item)
  end

  #--------------------------------------------------------------------------
  # alias method: display_critical
  #--------------------------------------------------------------------------
  alias window_battlelog_display_critical_abe display_critical
  def display_critical(target, item)
    return unless YEA::BATTLE::MSG_CRITICAL_HIT
    window_battlelog_display_critical_abe(target, item)
  end

  #--------------------------------------------------------------------------
  # alias method: display_miss
  #--------------------------------------------------------------------------
  alias window_battlelog_display_miss_abe display_miss
  def display_miss(target, item)
    return unless YEA::BATTLE::MSG_HIT_MISSED
    window_battlelog_display_miss_abe(target, item)
  end

  #--------------------------------------------------------------------------
  # alias method: display_evasion
  #--------------------------------------------------------------------------
  alias window_battlelog_display_evasion_abe display_evasion
  def display_evasion(target, item)
    if YEA::BATTLE::MSG_EVASION
      window_battlelog_display_evasion_abe(target, item)
    else
      if !item || item.physical?
        Sound.play_evasion
      else
        Sound.play_magic_evasion
      end
    end
  end

  #--------------------------------------------------------------------------
  # overwrite method: display_hp_damage
  #--------------------------------------------------------------------------
  def display_hp_damage(target, item)
    return if target.result.hp_damage == 0 && item && !item.damage.to_hp?
    if target.result.hp_damage > 0 && target.result.hp_drain == 0
      target.perform_damage_effect
    end
    #RPG::SE.new("TCO - Indicator2", 60, 100).play if target.result.hp_damage < 0
    Sound.play_recovery if target.result.hp_damage < 0
    return unless YEA::BATTLE::MSG_HP_DAMAGE
    add_text(target.result.hp_damage_text)
    wait
  end

  #--------------------------------------------------------------------------
  # overwrite method: display_mp_damage
  #--------------------------------------------------------------------------
  def display_mp_damage(target, item)
    return if target.dead? || target.result.mp_damage == 0
    RPG::SE.new("TCO - Indicator2", 65, 100).play if target.result.mp_damage < 0
    #RPG::SE.new("SFP Magic Song1 2", 60, 100).play if target.result.mp_damage < 0
    #Sound.play_recovery if target.result.mp_damage < 0
    return unless YEA::BATTLE::MSG_MP_DAMAGE
    add_text(target.result.mp_damage_text)
    wait
  end

  #--------------------------------------------------------------------------
  # overwrite method: display_tp_damage
  #--------------------------------------------------------------------------
  def display_tp_damage(target, item)
    return if target.dead? || target.result.tp_damage == 0
    #Sound.play_recovery if target.result.tp_damage < 0
    return unless YEA::BATTLE::MSG_TP_DAMAGE
    add_text(target.result.tp_damage_text)
    wait
  end

  #--------------------------------------------------------------------------
  # alias method: display_added_states
  #--------------------------------------------------------------------------
  alias window_battlelog_display_added_states_abe display_added_states
  def display_added_states(target)
    return unless YEA::BATTLE::MSG_ADDED_STATES
    window_battlelog_display_added_states_abe(target)
  end

  #--------------------------------------------------------------------------
  # alias method: display_removed_states
  #--------------------------------------------------------------------------
  alias window_battlelog_display_removed_states_abe display_removed_states
  def display_removed_states(target)
    return unless YEA::BATTLE::MSG_REMOVED_STATES
    window_battlelog_display_removed_states_abe(target)
  end

  #--------------------------------------------------------------------------
  # alias method: display_changed_buffs
  #--------------------------------------------------------------------------
  alias window_battlelog_display_changed_buffs_abe display_changed_buffs
  def display_changed_buffs(target)
    return unless YEA::BATTLE::MSG_CHANGED_BUFFS
    window_battlelog_display_changed_buffs_abe(target)
  end

end # Window_BattleLog
