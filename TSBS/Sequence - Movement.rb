#==============================================================================
# TSBS action sequences for grid movement
#------------------------------------------------------------------------------
module TSBS

  MovementPose = {

    "Actor_MoveSkill" => [
    [],
    [:script, "msgbox_p('A')"],
    [:script, "PhaseTurn.move_command(self)"],
    #[:script, "msgbox_p(self.name)"],
    [:goto_oripost, 16, 5],
    ],

    #------------------------------------------------------------------------------
  }

  AnimLoop.merge!(MovementPose) # <-- closure

end
