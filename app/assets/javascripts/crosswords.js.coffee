class Crossword
  @ALPHA: 'ABCDEFGHIJKLMNOPQRSTUVWXYZ'

  constructor: (@data) ->
    @solution = []
    @grid = []
    @direction = 'across'
    @row = 0
    @col = 0

    for i in [0...@data.height]
      @grid[i] = []
      @solution[i] = []
      for j in [0...@data.width]
        @solution[i][j] = @data.solution.charAt(i * @data.width + j)
        @grid[i][j] = $('<input>').prop('type', 'text')

        if @solution[i][j] == '.'
          @grid[i][j].addClass('black').prop('disabled', true)

  keypress: (code) ->
    switch (code)
      when 32 # spacebar
        @direction = (if @direction == 'across' then 'down' else 'across')
        @update_selected()

      when 8 # backspace key
        if @grid[@row][@col].val() == ''
          if @direction == 'across'
            @next_cell -1, 0
          else
            @next_cell 0, -1
        @grid[@row][@col].val('')

      when 37 then @next_cell -1,  0, true # left arrow
      when 38 then @next_cell  0, -1, true # up arrow
      when 39 then @next_cell  1,  0, true # right arrow
      when 40 then @next_cell  0,  1, true # down arrow

      else
        string = String.fromCharCode(code).toUpperCase()
        if Crossword.ALPHA.indexOf(string) >= 0
          @grid[@row][@col].val(string)
          if @direction == 'across' then @next_cell 1, 0 else @next_cell 0, 1

    false

  valid_cell: (row, col) ->
    0 <= col < @data.width && 0 <= row < @data.height &&
      !@grid[row][col].prop('disabled')

  next_cell: (dx, dy, skip_over_black = false) ->
    newcol = @col + dx
    newrow = @row + dy
    while skip_over_black && 0 <= newcol < @data.width &&
        0 <= newrow < @data.height &&
        @grid[newrow][newcol].prop('disabled')
      newcol += dx
      newrow += dy

    if @valid_cell(newrow, newcol)
      @grid[@row = newrow][@col = newcol].focus()
      @update_selected()

  # Updates the selected word to enter or the highlighted row in the grid. This
  # provides input to show where you're typing and what cells will be filled in
  update_selected: ->
    # Deselect everything first
    for row in @grid
      for input in row
        input.removeClass('selected')

    # Start initially at the cursor's location and move around from there
    r = @row
    c = @col
    dx = if @direction == 'across' then -1 else 0
    dy = -(dx + 1)

    # Go all the way backwards to the beginning of this word
    while @valid_cell(r + dy, c + dx)
      r += dy
      c += dx

    # Now go forwards and mark each cell as selected
    while @valid_cell(r, c)
      @grid[r][c].addClass('selected')
      r -= dy
      c -= dx

  setup: (@container) ->
    @container.addClass('grid')
    @container.children().remove()
    for input_row in @grid
      row = $('<div>').addClass('row')

      for input in input_row
        row.append input
        input.bind 'keydown', (event) =>
          if !event.metaKey && !event.ctrlKey && !event.altKey
            @keypress event.which

      @container.append row

    @container.click =>
      focused = @container.find('input:focus')
      return if focused.size == 0

      for i in [0...@data.height]
        for j in [0...@data.width]
          if @grid[i][j].get(0) == focused.get(0)
            @row = i
            @col = j
      @update_selected()

jQuery ->
  crossword = null

  $.getJSON '/crosswords/' + $('#crossword').data('id'), (data) ->
    crossword = new Crossword(data)
    crossword.setup $('#crossword')
