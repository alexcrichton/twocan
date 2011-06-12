#= require jquery
#= require jquery_ujs
#= require pjax
#= require_self
#= require_tree .

# When the page changes, update the arrow for navigation
$(document).bind 'pageChanged', ->
  $('nav .arrow').remove()
  $('nav a').each (_, el) ->
    if window.location.href == el.href
      $(el).append($('<div>').addClass('arrow'))

# When pjax starts, show the overlay with an ajax loader in the middle
$(document).bind 'start.pjax', ->
  hwidth = $('header').width()
  overlay = $('<div>').addClass('overlay')
  overlay.width($(document).width() - hwidth)
  overlay.css('left', $('header').width())
  loading = $('<div>').addClass('overlay-loading')

  $('#main').append(overlay)
  $('#main').append(loading)

  loading.css 'left', (overlay.width() - loading.width()) / 2 + hwidth
  loading.css 'top', (overlay.height() - loading.height()) / 2

window.flash_message = (klass, message) ->
  flash = $('<div>').addClass('flash').addClass(klass).html(message).hide()
  $(document.body).append(flash)
  flash.slideDown()
  setTimeout (-> flash.slideUp -> flash.remove()), 4000

jQuery ->
  setTimeout (-> $('.flash').slideUp -> $(this).remove()), 4000

  $('form').live 'ajax:aborted:file', (event, elements) ->
    i = 0
    form = $(this)
    i++ while $('#' + (id = 'iframe-upload-' + i)).length > 0

    iframe = $('<iframe />').attr({id: id, name: id}).hide()
    $(document.body).append(iframe)
    form.attr('target', id)

    form.trigger('ajax:beforeSend', null)
    iframe.load ->
      data = iframe.contents().find('pre').text()
      form.trigger('ajax:success', [data, null, null])
      form.trigger('ajax:complete', null)

      setTimeout -> iframe.remove()
      eval(data)
    true
