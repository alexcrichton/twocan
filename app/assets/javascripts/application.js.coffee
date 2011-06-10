#= require jquery
#= require jquery_ujs
#= require pjax

jQuery ->
  $('nav .current').append($('<div>').addClass('arrow'))
  
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

  $('nav a').click ->
    $('nav .arrow').remove()
    $(this).append($('<div>').addClass('arrow'))