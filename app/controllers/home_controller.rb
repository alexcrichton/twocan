class HomeController < ApplicationController

  skip_filter :verify_authenticity_token

  def auth
    response = Pusher[params[:channel_name]].authenticate(params[:socket_id])
    render :json => response
  end

end
