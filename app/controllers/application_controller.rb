class ApplicationController < ActionController::Base
  protect_from_forgery
  stream :if => :html_request?

  def html_request?
    request.format.to_s =~ /html/
  end

end
