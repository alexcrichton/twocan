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

  def current_authentication
    return @current_authentication if defined?(@current_authentication)
    @current_authentication = Authentication.where(
      :_id => session[:authentication]).first
  end

  def current_authentication= authentication
    @current_authentication = authentication
    session[:authentication] = authentication.id
  end

end
