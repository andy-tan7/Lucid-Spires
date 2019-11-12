# =============================================================================
# Theolized Sideview Battle System (TSBS)
# Version : 1.3
# Contact : www.rpgmakerid.com (or) http://theolized.blogspot.com
# (English Language)
# -----------------------------------------------------------------------------
# Requires : Theo - Basic Modules v1.5b
# >> Basic Functions
# >> Movement
# >> Core Result
# >> Core Fade
# >> Clone Image
# >> Rotate Image
# >> Smooth Move
# =============================================================================
=begin

  Introduction :
  Move addons is a trick to split action sequence in different script slot to
  gain more control on you sequences

  How to make move addon :
  - Insert a new script below TSBS
  - Start with "module TSBS"
  - End it with keyword "end"
  - Insert any constant name you want between "module TSBS" and "end". Start
    it with capital letter. For example "Stella_Moves"
  - Add = {} symbol after the name you just typed
  - Define new action sequences inside {}
  - Adds AnimLoop.merge!(Your_Inputed_Name) in the end of line

  The simple example would be like this
-------------------------------------------------------------------------------
=end

module TSBS

  ClementPose = {

    "Cast_Light" => [
    [],
    [:pose, 1,40,6],
    [:pose, 1,41,6],
    [:pose, 1,42,4],
    [:cast, 43],
    [:pose, 1,43,24],
    ],

    "Spell_Saint" => [
    [],
    [:pose, 1, 40, 3],
    [:pose, 1, 41, 3],
    [:cast, 43],
    [:pose, 1, 42, 3],
    [:pose, 1, 43, 36],
    [:pose, 1, 28, 24],
    [:pose, 1, 25, 3],
    [:pose, 1, 26, 3],
    [:show_anim],
    [:pose, 1, 27, 10],
    [:target_damage],
    [:wait, 12],
    ]

  }

  AnimLoop.merge!(ClementPose) # <-- closure

end
