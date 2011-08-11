jQuery ->
  $('.reveal-letter').live 'click', ->
    console.log 'reveal'
    letter = crossword.solution[crossword.row][crossword.col]
    crossword.insert_character letter
    false

  $('.check-puzzle').live 'click', ->
    if crossword.check()
      alert 'All good!'
    false

  $('.clear-puzzle').live 'click', ->
    if confirm 'Sure?'
      crossword.clear()
    false
