class HomeController < ApplicationController

  skip_filter :verify_authenticity_token, :only => :pusher_auth

  def pusher_auth
    response = Pusher[params[:channel_name]].authenticate(params[:socket_id])
    render :json => response
  end

  def omniauth
    self.current_authentication = Authentication.find_or_initialize_by(
      :provider => env['omniauth.auth']['provider'],
      :uid      => env['omniauth.auth']['uid']
    )

    current_authentication.token ||= session[:token]
    current_authentication.save!

    # If we created some crosswords, and then logged in to a previously created
    # account, then we should take ownership of all the crosswords
    Crossword.where(:session_token => session[:token]).
      update_all(:session_token => current_authentication.token)

    flash[:notice] = 'Logged in!'
    redirect_to root_path
  end

end
