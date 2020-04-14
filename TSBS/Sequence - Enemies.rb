module TSBS

  Sequence_EnemyCommon = {

  # ---------------------------------------------------------------------------
  # Enemy Sequence - Chiro (Wolf)
  # ---------------------------------------------------------------------------
  "Chiro_IDLE" => [
  #[Loop, afterimage, flip]
  [true, false, true],
  [:pose, 1,  6,  14],
  [:pose, 1,  7,  14],
  [:pose, 1,  8,  18],
  [:pose, 1,  7,  14],
  ],
  "Chiro_CRITICAL" => [
  [true, false, true],
  [:pose, 1, 3, 9],
  [:pose, 1, 4, 9],
  [:pose, 1, 5, 14],
  [:pose, 1, 4, 9],
  ],
  "Chiro_DEATH" => [
  [false,false,true],
  [:slide, 9, 0, 5, 0],
  [:pose, 1, 9, 8],
  [:wait, 4],
  [:pose, 1, 6, 5],
  [:pose, 1, 7, 5],
  [:pose, 1, 8, 18],
  [:collapse],
  [:wait, 18],
  ],
  "Chiro_RETURN" => [
  #[Loop, afterimage, flip]
  [true, false, false],
  [:goto_oripost, 22,1],
  [:pose, 1,  13,  6],
  [:pose, 1,  14,  6],
  [:pose, 1,  15,  6],
  [:pose, 1,  16,  6],
  ],
  "Chiro_FRETURN" => [
  #[Loop, afterimage, flip]
  [true, false, true],
  [:goto_oripost, 24,1],
  [:pose, 1,  13,  6],
  [:pose, 1,  14,  6],
  [:pose, 1,  15,  6],
  [:pose, 1,  16,  6],
  ],
  "Chiro_HURT" => [
  [false, false, true],
  [:slide, 9, 0, 5, 0],
  [:pose, 1, 9, 24],
  [:wait, 10],
  [:goto_oripost, 3, 0],
  ],
  "Chiro_SleepBuff" => [
  [false, false, true],
  [:pose, 1, 8, 26],
  [:show_anim],
  [:pose, 1, 8, 44],
  [:pose, 1, 7, 6],
  [:pose, 1, 6, 6],
  [:pose, 1, 4, 8],
  [:pose, 1, 5, 8],
  [:pose, 1, 1, 11],
  [:pose, 1, 0, 11],
  [:pose, 1, 1, 11],
  [:pose, 1, 2, 11],
  [:pose, 1, 1, 11],
  [:pose, 1, 0, 11],
  [:pose, 1, 2, 11],
  [:pose, 1, 1, 11],
  [:target_damage],
  ],
  "Chiro_Attack" => [
  [],
  [:action, "Show_Range"],
  [:move_to_targ_s, 65, 10, 7, 1],
  [:pose, 1, 12, 4],
  [:pose, 1, 13, 4],
  [:pose, 1, 14, 4],
  [:if, "self.moving?", [:pose, 1, 15, 4]],
  [:if, "self.moving?", [:pose, 1, 16, 4]],
  [:if, "self.moving?", [:pose, 1, 13, 4]],
  [:if, "self.moving?", [:pose, 1, 14, 4]],
  [:if, "self.moving?", [:pose, 1, 15, 4]],
  [:if, "self.moving?", [:pose, 1, 16, 4]],
  [:pose, 1, 17, 5],
  [:move_to_target, 55, 11, 5, 3],
  [:pose, 1, 18, 3],
  [:show_anim],
  [:pose, 1, 19, 15],
  [:wait, 8],
  [:target_damage],
  [:wait, 8],
  ],


#------------------------------------------------------------------------------
  }
  AnimLoop.merge!(Sequence_EnemyCommon)
end
