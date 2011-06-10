#= require jquery
#= require jquery_ujs
#= require pjax

$(document).bind 'pageChanged', ->
  console.log 'here'
  $('nav .arrow').remove()
  $('nav a').each (_, el) ->
    if window.location.href == el.href
      $(el).append($('<div>').addClass('arrow'))

jQuery ->
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
