class CrosswordsController < ApplicationController

  respond_to :html
  load_and_authorize_resource :find_by => :slug

  def index
    @crosswords = @crosswords.where :session_token => session[:token]
    respond_with @crosswords
  end

  def show
    respond_with @crossword do |format|
      format.json
      format.puz {
        send_data @crossword.to_puz, :type => Mime['puz'].to_s,
          :filename => 'crossword.puz'
      }
    end
  end

  def new
    respond_with @crossword
  end

  def create
    @crossword.session_token = session[:token]
    @crossword.save

    respond_with @crossword
  end

  def destroy
    @crossword.destroy

    respond_with :crosswords
  end

end
