#= require collaborate

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
        @grid[i][j] = $('<input>').prop('type', 'text').addClass('cell')

        if @solution[i][j] == '.'
          @grid[i][j].addClass('black').prop('disabled', true)

  # Handler for a keypress event anywhere in the crossword. This assumes that
  # the context of the function is the crossword object.
  keypress: (event) ->
    # Ignore these special events because they might be browser shortcuts and
    # we don't want to interfere with any of them
    return if event.metaKey || event.ctrlKey || event.altKey

    switch (event.which)
      when 8 # backspace key
        if @grid[@row][@col].val() == ''
          if @direction == 'across'
            @next_cell -1, 0
          else
            @next_cell 0, -1
        if @grid[@row][@col].val() != ''
          @grid[@row][@col].val('')
          @container.trigger 'crossword:remove-letter',
            row: @row
            col: @col

      when 32 then @invert_direction() # spacebar
      when 37 then @next_cell -1,  0, true # left arrow
      when 38 then @next_cell  0, -1, true # up arrow
      when 39 then @next_cell  1,  0, true # right arrow
      when 40 then @next_cell  0,  1, true # down arrow

      else
        string = String.fromCharCode(event.which).toUpperCase()
        if Crossword.ALPHA.indexOf(string) >= 0
          if @grid[@row][@col].val() != string
            @container.trigger 'crossword:new-letter',
              row: @row
              col: @col
              letter: string

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

    @select newrow, newcol if @valid_cell(newrow, newcol)

  # Invert the currently selected direction
  invert_direction: ->
    @direction = (if @direction == 'across' then 'down' else 'across')
    @update_highlighting 'selected'
    @fire_selected_event()

  # Updates the selected word to enter or the highlighted row in the grid. This
  # provides input to show where you're typing and what cells will be filled in
  update_highlighting: (klass, row = @row, col = @col, dir = @direction) ->
    # Deselect everything first
    for r in @grid
      for input in r
        input.removeClass(klass)

    # Start initially at the cursor's location and move around from there
    dx = if dir == 'across' then -1 else 0
    dy = -(dx + 1)

    # Go all the way backwards to the beginning of this word
    while @valid_cell(row + dy, col + dx)
      row += dy
      col += dx

    # Now go forwards and mark each cell as selected
    while @valid_cell(row, col)
      @grid[row][col].addClass(klass)
      row -= dy
      col -= dx

  fire_selected_event: ->
    row = @row
    col = @col
    row-- while @valid_cell(row - 1, @col)
    col-- while @valid_cell(@row, col - 1)
    across_number = parseInt @grid[@row][col].siblings('span').text(), 10
    down_number   = parseInt @grid[row][@col].siblings('span').text(), 10
    event = {row:@row, col:@col, direction:@direction}

    for clue in @data.clues
      if clue.direction == 'across' && clue.number == across_number
        if @direction == 'across'
          event.primary = clue
        else
          event.secondary = clue
      else if clue.direction == 'down' && clue.number == down_number
        if @direction == 'across'
          event.secondary = clue
        else
          event.primary = clue

    @container.trigger 'crossword:word-selected', event

  # Select a cell in the crossword based on the row and column it's located at.
  # You can also supply an optional direction for the selection to have
  select: (row, column, direction = @direction) ->
    return if row == @row && column == @col && direction == @direction
    @row       = row
    @col       = column
    @direction = direction

    @grid[@row][@col].focus() # Make sure the input is focused
    @update_highlighting 'selected' # Nice visual indication of word selected
    @fire_selected_event()    # Tell the container what clues have been selected

  # Base the current selected box of the crossword on an input element. The
  # input should be a jQuery element
  select_input: (input) ->
    for i in [0...@data.height]
      for j in [0...@data.width]
        if @grid[i][j].get(0) == input.get(0)
          return @select i, j

  # Base the current selected box in the crossword on a clue. The clue is
  # specified by its number and its direction.
  select_clue: (number, direction) ->
    for clue in @data.clues
      if clue.number == number and clue.direction == direction
        return @select(clue.row, clue.column, clue.direction)

  # Setup the given container to be a crossword. All of the event handlers are
  # installed here. This assumes that jQuery is available
  setup: (@container) ->
    # Clear whatever was previously in the container
    @container.addClass('grid')
    @container.children().remove()

    # Put all inputs into the grid (also specify rows)
    for input_row in @grid
      row = $('<div>').addClass('row')
      for input in input_row
        row.append input
      @container.append row

    # Now go back and replace all inputs which are the start of clues with a
    # wrapper so we can fit in a span with the number of the clue
    for clue in @data.clues
      input = @grid[clue.row][clue.column]
      continue if input.parent().hasClass('cell') # already marked?

      outer = $('<div>').addClass('cell')
      outer.insertBefore(input)
      outer.append(input.remove())
      outer.append($('<span>').text(clue.number))

    # Now install the event handlers when we're done moving everything around
    for row in @grid
      for input in row
        input.bind 'keydown', (event) => @keypress event

    # Some handlers for selecting a square to enter from
    @container.find('input').click (event) =>
      @select_input $(event.currentTarget)
    @container.find('input').dblclick (event) => @invert_direction()
    # In case you hit the span instead of the input, also focus the input
    @container.find('span').click (event) =>
      @select_input $(event.currentTarget).siblings('input')

jQuery ->
  $.getJSON '/crosswords/' + $('#crossword').data('id'), (data) ->
    window.crossword = new Crossword(data)
    crossword.setup $('#crossword')

  $('#crossword').bind 'crossword:word-selected', (_, clues) ->
    $('li.selected').removeClass('selected')
    $('li.semi-selected').removeClass('semi-selected')

    if clues.primary
      $('#' + clues.primary.direction +
          ' li[value=' + clues.primary.number + ']').addClass('selected')

    if clues.secondary
      $('#' + clues.secondary.direction +
          ' li[value=' + clues.secondary.number + ']').addClass('semi-selected')

  # Click a clue to get to the cells where it's located
  $('.clues li').click ->
    type   = $(this).closest('.clues').prop('id')
    number = $(this).prop('value')
    crossword.select_clue number, type
