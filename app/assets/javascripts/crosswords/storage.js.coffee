jQuery ->
  return unless window.localStorage

  container = $('#crossword')

  window.identifier = 'crossword-saved-' + container.data('id')
  set = (key, value) ->
    try
      hash = JSON.parse(localStorage[identifier])
    catch err
      hash = {}
    hash[key] = value
    localStorage[identifier] = JSON.stringify(hash)

  get = (key) ->
    try
      JSON.parse(localStorage[identifier])[key]
    catch err
      undefined

  container.bind 'crossword:loaded', ->
    selection = get 'selection'
    if selection
      crossword.select selection.row, selection.col, selection.dir
    progress = get 'progress'
    if progress
      crossword.load_progress progress

  container.bind 'crossword:new-letter', ->
    set 'progress', crossword.progress()
  container.bind 'crossword:remove-letter', ->
    set 'progress', crossword.progress()
  container.bind 'crossword:word-selected', (_, data) ->
    set 'selection', {row: data.row, col: data.col, dir: data.direction}
