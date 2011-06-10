jQuery ->
  $('.reveal-letter').click ->
    letter = crossword.solution[crossword.row][crossword.col]
    crossword.insert_character letter
    false

  $('.check-puzzle').click ->
    if crossword.check()
      alert 'All good!'
    false

  $('.clear-puzzle').click ->
    if confirm 'Sure?'
      crossword.clear()
    false
