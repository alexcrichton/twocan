jQuery ->
  $('.reveal .letter').click ->
    letter = crossword.solution[crossword.row][crossword.col]
    crossword.insert_character letter
    false