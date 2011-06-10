class ApplicationController < ActionController::Base
  before_filter :ensure_session_token
  protect_from_forgery
  stream :if => :html_request?

  def ensure_session_token
    session[:token] ||= SecureRandom.hex(15)
  end

  def html_request?
    request.format.to_s =~ /html/
  end

end
