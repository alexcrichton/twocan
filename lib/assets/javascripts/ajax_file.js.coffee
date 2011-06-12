$('form').live 'ajax:aborted:file', (event, elements) ->
  i = 0
  form = $(this)
  i++ while $('#' + (id = 'iframe-upload-' + i)).length > 0

  iframe = $('<iframe />').attr(id: id, name: id).hide()
  $(document.body).append(iframe)
  form.attr('target', id)
  form.append $('<input>', type: 'hidden', name: 'format', value: 'js')

  # form.trigger('ajax:beforeSend', null)
  iframe.load ->
    data = iframe.contents().find('pre').text()
    form.trigger('ajax:success', [data, null, null])
    form.trigger('ajax:complete', null)

    setTimeout -> iframe.remove()
    eval(data)
  true
