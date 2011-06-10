module ApplicationHelper

  def nav_link text, url
    klass = url == request.path ? 'current' : ''

    link_to text, url, :class => klass
  end

end
