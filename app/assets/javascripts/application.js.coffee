#= require jquery
#= require jquery_ujs
#= require pjax
#= require_self
#= require_tree .
#= require ajax_file

# When the page changes, update the arrow for navigation
$(document).bind 'pageChanged', ->
  $('nav .arrow').remove()
  $('nav a').each (_, el) ->
    if window.location.href == el.href
      $(el).append($('<div>').addClass('arrow'))

# When pjax starts, show the overlay with an ajax loader in the middle
$(document).bind 'start.pjax', ->
  overlay = $('<div>').addClass('overlay')
  loading = $('<div>').addClass('overlay-loading')

  $('#main').append(overlay)
  $('#main').append(loading)

  loading.css 'left', (overlay.width() - loading.width()) / 2
  loading.css 'top', (overlay.height() - loading.height()) / 2

window.flash = (klass, message) ->
  flash = $('<div>').addClass('flash').addClass(klass).html(message).hide()
  $(document.body).append(flash)
  flash.slideDown()
  setTimeout (-> flash.slideUp -> flash.remove()), 4000

jQuery ->
  setTimeout (-> $('.flash').slideUp -> $(this).remove()), 4000
