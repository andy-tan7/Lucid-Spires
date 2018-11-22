#===========================================================================
# ** Revoked Message Sound Effect
#---------------------------------------------------------------------------
#  This script adds a sound effect to message box character processing.
#===========================================================================
module Revoked
  module Msg

    DELAY = 2

  end
end

module Sound

  def self.message_blip(pitch = 100)
    RPG::SE.new("FER - Sys_Msg1", 50, pitch).play
  end

end


class Window_Message < Window_Base

  alias rvkd_msg_se_clear_flags clear_flags
  def clear_flags
    rvkd_msg_se_clear_flags
    @sound_frame = 0
  end

  alias rvkd_msg_se_process_normal_character process_normal_character
  def process_normal_character(c, pos)
    play_message_sound
    rvkd_msg_se_process_normal_character(c, pos)
  end

  def play_message_sound
    Sound.message_blip if @sound_frame <= 0
    @sound_frame = @sound_frame >= Revoked::Msg::DELAY ? 0 : @sound_frame + 1
  end

end
