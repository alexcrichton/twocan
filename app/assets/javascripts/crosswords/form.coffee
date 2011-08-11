jQuery ->
  $('form.new_crossword .file-input .button, form.new_crossword :text').live 'click', ->
    $(this).closest('form').find(':file').click()
    false

  $('form.new_crossword :file').live 'change', ->
    sanitized = $(this).val().replace(/^C:\\fakepath\\/, '')
    $(this).closest('form').find(':text').val(sanitized)

  $('form.new_crossword .help a').live 'click', ->
    $(this).siblings('.info').slideToggle();
    false
