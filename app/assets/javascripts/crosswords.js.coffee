#= require jquery/scrollto
#= require crosswords/storage
#= require_self
#= require crosswords/collaborate
#= require crosswords/reveal

# Represents a crossword to be done.
#
# The crossword's container emits events when they happen. You can bind to them
# with jQuery. Each is described below with the event name, description of what
# it does, and then the data that the event object has.
#
#   loaded => the crossword has been set up and loaded. Ready for play
#     no data
#
#   new-letter => a new letter has been typed
#     row: (integer) row of letter
#     col: (integer) column of letter
#     letter: (string) typed letter
#
#   remove-letter => a new letter has been removed
#     row: (integer) row of letter
#     col: (integer) column of letter
#
#   clue-solved => a clue has been solved (it might not be right)
#     primary: (clue) clue that was solved in the selected direction
#     secondary: (clue) clue, if any, that was solved in the non-selecte dir
#
#   clue-unsolved => a clue has been unsolved
#     arguments are same as clue-solved, except they're clues that were unsolved
#
#   word-selected => a new word has been selected
#     primary: (clue) same as clue-solved, but clue that is selected
#     secondary: (clue) same as clue-solved, but clue that is selected
#     row: (integer) row of cursor
#     col: (integer) column of cursor
#     direction: (string) either 'across' or 'down', current direction
class Crossword
  @ALPHA: 'ABCDEFGHIJKLMNOPQRSTUVWXYZ'

  constructor: (data) ->
    @solution  = []
    @grid      = []
    @direction = 'across'
    @row       = 0
    @col       = 0
    @height    = data.height
    @width     = data.width
    @clues     = data.clues
    @sections  = data.sections

    for i in [0...@height]
      @grid[i] = []
      @solution[i] = []
      for j in [0...@width]
        @solution[i][j] = data.solution.charAt(i * @width + j)
        @grid[i][j] = $('<input>').prop('type', 'text')

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

  # Insert a given character at the specified location. This is either called
  # from a websocket handler or from the keyboard handler.
  #
  # @param [String] character the one character string that should be input
  # @param [Integer] row the row to insert at (defaults to @row)
  # @param [Integer] col the column to insert at (defaults to @col)
  # @param [Boolean] local_event flag if this was a local event and extra
  #   events should be triggered as a result
  insert_character: (character, row = @row, col = @col, local_event = true) ->
    if @grid[row][col].val() != character
      @grid[row][col].val(character)
      @grid[row][col].parent().removeClass('wrong')
      if local_event
        @container.trigger 'new-letter',
          row: @row
          col: @col
          letter: character
      clues     = @get_clues(row, col)
      completed = {}
      completed.primary   = clues.primary   if @clue_finished clues.primary
      completed.secondary = clues.secondary if @clue_finished clues.secondary
      @container.trigger 'clue-solved', completed

    # Move the cursor if we can (only local events)
    if local_event
      if @direction == 'across' then @next_cell 1, 0 else @next_cell 0, 1

  # Tests whether a clue has been completed (completely filled in)
  clue_finished: (clue) ->
    return false unless clue

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
  backspace: (row = @row, col = @col, local_event = true) ->
    if local_event && @grid[row][col].val() == ''
      if @direction == 'across'
        @next_cell -1, 0
      else
        @next_cell 0, -1
      row = @row
      col = @col

    if @grid[row][col].val() != ''
      @grid[row][col].val('')
      @container.trigger 'clue-unsolved', @get_clues(row, col)
      if local_event
        @container.trigger 'remove-letter', row: row, col: col

  # Tests whether a (row, col) combination point to a valid location in the
  # grid. A valid location is within bounds and also not a black square
  valid_cell: (row, col) ->
    0 <= col < @width && 0 <= row < @height &&
      !@grid[row][col].prop('disabled')

  # Conditionally goes to the next cell, using the specified delta distances
  # One of the distances should be 0 while the other is 1 or -1.
  # If skip_over_black is specified, then black squares don't stop movement,
  # but rather movement skips over them
  next_cell: (dx, dy, skip_over_black = false) ->
    newcol = @col + dx
    newrow = @row + dy
    while skip_over_black && 0 <= newcol < @width &&
        0 <= newrow < @height &&
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
    current_class = klass.replace(/selected/, 'current')
    # Deselect everything first
    for r in @grid
      for input in r
        input.parent().removeClass(klass).removeClass(current_class)

    @grid[row][col].parent().addClass(current_class)

    # Start initially at the cursor's location and move around from there
    dx = if dir == 'across' then -1 else 0
    dy = -(dx + 1)

    # Go all the way backwards to the beginning of this word
    while @valid_cell(row + dy, col + dx)
      row += dy
      col += dx

    # Now go forwards and mark each cell as selected
    while @valid_cell(row, col)
      @grid[row][col].parent().addClass(klass)
      row -= dy
      col -= dx

  # Fire an event which indicates that the selection has changed
  fire_selected_event: ->
    event = @get_clues()
    event.row = @row
    event.col = @col
    event.direction = @direction

    @container.trigger 'word-selected', event

  # Get the two relevant clues (if there are two) for the selected row and
  # columnt. The object returned has a 'primary' and 'secondary' key where the
  # 'primary' key is the clue in the same direction as is currently working and
  # the secondary is the other direction
  get_clues: (row = @row, col = @col) ->
    orig_row = row
    orig_col = col
    row-- while @valid_cell(row - 1, orig_col)
    col-- while @valid_cell(orig_row, col - 1)
    across_number = parseInt @grid[orig_row][col].siblings('span').text(), 10
    down_number   = parseInt @grid[row][orig_col].siblings('span').text(), 10
    clues = {}

    for clue in @clues
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
    for i in [0...@height]
      for j in [0...@width]
        if @grid[i][j].get(0) == input.get(0)
          if i == @row && j == @col
            return @invert_direction()
          else
            return @select i, j

  # Base the current selected box in the crossword on a clue. The clue is
  # specified by its number and its direction.
  select_clue: (number, direction) ->
    for clue in @clues
      if clue.number == number and clue.direction == direction
        return @select(clue.row, clue.column, clue.direction)

  # Serialize the progress of this crossword into a string. The string will
  # have height * width characters and will represent the grid traversed from
  # left to right and top to bottom. A '.' means a black square, a '-' means
  # a blank square, and a letter means that that's been typed in
  progress: ->
    progress = ''
    for row in @grid
      for input in row
        if input.is(':disabled')
          progress += '.'
        else if input.val() == ''
          progress += '-'
        else
          progress += input.val()

    progress

  # Load a serialized crossword's progress into this crossword.
  #
  # @param [String] progress a string generated by #progress previously
  load_progress: (progress) ->
    for i in [0...@height]
      for j in [0...@width]
        char = progress.charAt 0
        progress = progress.substring 1
        switch char
          when '.' then continue
          when '-' then @grid[i][j].val('')
          else @insert_character char, i, j, false

  # Check this puzzle's progress. Marks all cells which have values that are
  # wrong with the 'wrong' class
  check: () ->
    all_right = true

    for i in [0...@height]
      for j in [0...@width]
        continue if @grid[i][j].prop('disabled')
        if @grid[i][j].val() == ''
          all_right = false
        else if @grid[i][j].val() != @solution[i][j]
          @grid[i][j].parent().addClass('wrong')
          all_right = false

    all_right

  # Clear's all current progress with this crossword
  clear: () ->
    for i in [0...@height]
      for j in [0...@width]
        @backspace i, j, false

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
        cell = $('<div>').addClass('cell')
        cell.append input
        row.append cell
      @container.append row

    # Now go back and replace all inputs which are the start of clues with a
    # wrapper so we can fit in a span with the number of the clue
    for clue in @clues
      input = @grid[clue.row][clue.column]
      continue if input.parent().find('span').length > 0 # already marked?
      $('<span>').text(clue.number).insertAfter(input)

    gext = null
    for section in @sections
      gext = section.data if section.title == 'GEXT'
    for i in [0...@height]
      for j in [0...@width]
        # See http://code.google.com/p/puz/wiki/FileFormat
        if gext && gext[i * @width + j] & 0x80
          $('<div>', class: 'circle').insertAfter @grid[i][j]

        if @solution[i][j] == '.'
          @grid[i][j].prop('disabled', true).parent().addClass('black')

    # Now install the event handlers when we're done moving everything around
    for row in @grid
      for input in row
        input.bind 'keydown', (event) => @keypress event

    # Some handlers for selecting a square to enter from
    @container.find('input').click (event) =>
      @select_input $(event.currentTarget)
    # In case you hit the span instead of the input, also focus the input
    @container.find('span, .circle').click (event) =>
      @select_input $(event.currentTarget).siblings('input')

    @container.trigger 'loaded'

window.setup_crossword = (container) ->
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

  # When the word selection changes, change how the clue looks in the lists
  container.bind 'word-selected.crossword', (_, clues) ->
    $('li.selected').removeClass('selected')
    $('li.semi-selected').removeClass('semi-selected')

    each_clue clues, (clue, primary, selector) ->
      element = $(selector)
      element.addClass(if primary then 'selected' else 'semi-selected')
      element.closest('ol').scrollTo element, 100

      $('.current-clue').text clue.text if primary

  # When words are solved/unsolved, update classes appropriately
  container.bind 'clue-unsolved.crossword', (_, clues) ->
    each_clue clues, (_, _, selector) -> $(selector).removeClass('solved')
  container.bind 'clue-solved.crossword', (_, clues) ->
    each_clue clues, (_, _, selector) -> $(selector).addClass('solved')

  # Click a clue to get to the cells where it's located
  $('.clues li').click ->
    type   = $(this).closest('.clues').prop('id')
    number = $(this).prop('value')
    crossword.select_clue number, type

  # Actually set up the crossword now
  window.crossword = new Crossword(container.data('crossword'))
  setup_storage container
  crossword.setup container
  establish_channel container
  container.prepend $('<div>', class: 'current-clue')

  $(document).one 'start.pjax', -> container.unbind('.crossword')
