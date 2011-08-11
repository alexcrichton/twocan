window.setup_storage = (container) ->
  return unless window.localStorage

  identifier = 'crossword-saved-' + container.data('id')
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

  container.bind 'loaded.crossword', ->
    selection = get 'selection'
    if selection
      crossword.select selection.row, selection.col, selection.dir
    progress = get 'progress'
    if progress
      crossword.load_progress progress

  container.bind 'new-letter.crossword', ->
    set 'progress', crossword.progress()
  container.bind 'remove-letter.crossword', ->
    set 'progress', crossword.progress()
  container.bind 'word-selected.crossword', (_, data) ->
    set 'selection', {row: data.row, col: data.col, dir: data.direction}
  container.bind 'remote-action.crossword', ->
    set 'progress', crossword.progress()
