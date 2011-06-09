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
      when 8  then @backspace()            # backspace key
      when 32 then @invert_direction()     # spacebar
      when 37 then @next_cell -1,  0, true # left arrow
      when 38 then @next_cell  0, -1, true # up arrow
      when 39 then @next_cell  1,  0, true # right arrow
      when 40 then @next_cell  0,  1, true # down arrow

      else
        # Only insert characters which are upper case and alphabetic
        string = String.fromCharCode(event.which).toUpperCase()
        @insert_character(string) if Crossword.ALPHA.indexOf(string) >= 0

    # Don't do whatever the default is because we took care of it. It's easier
    # to take care of it in most cases because there's just too many edge cases
    # that would have to be dealt with otherwise
    false

  insert_character: (character) ->
    if @grid[@row][@col].val() != character
      @grid[@row][@col].val(character)
      @container.trigger 'crossword:new-letter',
        row: @row
        col: @col
        letter: character
      clues     = @get_clues()
      completed = {}
      completed.primary   = clues.primary   if @clue_finished clues.primary
      completed.secondary = clues.secondary if @clue_finished clues.secondary
      @container.trigger 'crossword:clue-solved', completed

    # Move the cursor if we can
    if @direction == 'across' then @next_cell 1, 0 else @next_cell 0, 1

  # Tests whether a clue has been completed (completely filled in)
  clue_finished: (clue) ->
    # Start initially at the clue's location and then move across it
    row = clue.row
    col = clue.column
    dx = if clue.direction == 'across' then 1 else 0
    dy = 1 - dx

    # Go all the way backwards to the beginning of this word
    while @valid_cell(row, col)
      return false if @grid[row][col].val() == ''
      row += dy
      col += dx

    # Everything wasn't blank, the clue is filled in
    true

  # Called whenver backspace is hit. This will delete the necessary characters
  # and call the necessary callbacks.
  backspace: ->
    if @grid[@row][@col].val() == ''
      if @direction == 'across'
        @next_cell -1, 0
      else
        @next_cell 0, -1

    if @grid[@row][@col].val() != ''
      @grid[@row][@col].val('')
      @container.trigger 'crossword:clue-unsolved', @get_clues()
      @container.trigger 'crossword:remove-letter', row: @row, col: @col

  # Tests whether a (row, col) combination point to a valid location in the
  # grid. A valid location is within bounds and also not a black square
  valid_cell: (row, col) ->
    0 <= col < @data.width && 0 <= row < @data.height &&
      !@grid[row][col].prop('disabled')

  # Conditionally goes to the next cell, using the specified delta distances
  # One of the distances should be 0 while the other is 1 or -1.
  # If skip_over_black is specified, then black squares don't stop movement,
  # but rather movement skips over them
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
        input.removeClass(klass).removeClass('current')

    @grid[row][col].addClass('current')

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

  # Fire an event which indicates that the selection has changed
  fire_selected_event: ->
    event = @get_clues()
    event.row = @row
    event.col = @col
    event.direction = @direction

    @container.trigger 'crossword:word-selected', event

  # Get the two relevant clues (if there are two) for the selected row and
  # columnt. The object returned has a 'primary' and 'secondary' key where the
  # 'primary' key is the clue in the same direction as is currently working and
  # the secondary is the other direction
  get_clues: ->
    row = @row
    col = @col
    row-- while @valid_cell(row - 1, @col)
    col-- while @valid_cell(@row, col - 1)
    across_number = parseInt @grid[@row][col].siblings('span').text(), 10
    down_number   = parseInt @grid[row][@col].siblings('span').text(), 10
    clues = {}

    for clue in @data.clues
      if clue.direction == 'across' && clue.number == across_number
        if @direction == 'across'
          clues.primary = clue
        else
          clues.secondary = clue
      else if clue.direction == 'down' && clue.number == down_number
        if @direction == 'across'
          clues.secondary = clue
        else
          clues.primary = clue

    clues

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
          if i == @row && j == @col
            return @invert_direction()
          else
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
    # In case you hit the span instead of the input, also focus the input
    @container.find('span').click (event) =>
      @select_input $(event.currentTarget).siblings('input')

jQuery ->
  # Helper function to run a callback on each clue from an event created
  # by the crossword. The three arguments to the callback are:
  #  1. the clue object
  #  2. boolean if the clue is the primary clue
  #  3. a string selector to the clue's <li> tag
  each_clue = (clues, fn) ->
    if clues.primary
      fn clues.primary, true, '#' + clues.primary.direction +
          ' li[value=' + clues.primary.number + ']'
    if clues.secondary
      fn clues.secondary, false, '#' + clues.secondary.direction +
          ' li[value=' + clues.secondary.number + ']'

  # Actually get this crossword's information
  # $.getJSON '/crosswords/' + $('#crossword').data('id'), (data) ->
  container = $('#crossword')
  window.crossword = new Crossword(container.data('crossword'))
  crossword.setup container

  # When the word selection changes, change how the clue looks in the lists
  container.bind 'crossword:word-selected', (_, clues) ->
    $('li.selected').removeClass('selected')
    $('li.semi-selected').removeClass('semi-selected')

    each_clue clues, (clue, primary, selector) ->
      $(selector).addClass(if primary then 'selected' else 'semi-selected')

  # When words are solved/unsolved, update classes appropriately
  container.bind 'crossword:clue-unsolved', (_, clues) ->
    each_clue clues, (_, _, selector) -> $(selector).removeClass('solved')
  container.bind 'crossword:clue-solved', (_, clues) ->
    each_clue clues, (_, _, selector) -> $(selector).addClass('solved')

  # Click a clue to get to the cells where it's located
  $('.clues li').click ->
    type   = $(this).closest('.clues').prop('id')
    number = $(this).prop('value')
    crossword.select_clue number, type
