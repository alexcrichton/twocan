#= require pusher

window.establish_channel = (container) ->
  window.pusher ||= new Pusher(window.pusher_key)
  channel = window.pusher.subscribe 'private-' + container.data('id')

  container.bind 'word-selected.crossword', (_, data) ->
    channel.trigger 'client-word-selected', data
  container.bind 'new-letter.crossword', (_, data) ->
    channel.trigger 'client-new-letter', data
  container.bind 'remove-letter.crossword', (_, data) ->
    channel.trigger 'client-remove-letter', data
  container.bind 'checked.crossword', ->
    channel.trigger 'client-checked', {}

  channel.bind 'client-word-selected', (data) ->
    row = parseInt(data.row, 10)
    col = parseInt(data.col, 10)
    window.crossword.update_highlighting 'selected2', row, col, data.direction

  channel.bind 'client-new-letter', (data) ->
    row = parseInt(data.row, 10)
    col = parseInt(data.col, 10)
    window.crossword.insert_character data.letter, row, col, false
    container.trigger 'remote-action'

  channel.bind 'client-remove-letter', (data) ->
    row = parseInt(data.row, 10)
    col = parseInt(data.col, 10)
    window.crossword.backspace row, col, false
    container.trigger 'remote-action'

  channel.bind 'client-checked', (data) -> window.crossword.check false

  $(document).one 'start.pjax', -> channel.disconnect()
