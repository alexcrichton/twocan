class CrosswordsController < ApplicationController

  respond_to :html
  load_and_authorize_resource :find_by => :slug

  def index
    @crosswords = @crosswords.where :session_token => session[:token]
    @crosswords = @crosswords.searchq(params[:q]).order(:title.asc).
      page(params[:page]).per(20)
    respond_with @crosswords
  end

  def show
    respond_with @crossword do |format|
      format.json
      format.puz
    end
  end

  def new
    respond_with @crossword
  end

  def create
    @crossword.session_token = session[:token]

    if @crossword.save
      redirect_pjax_to :show, @crossword
    else
      # render create.js.erb (respond_with @crossword doesn't work?!)
    end
  end

  def destroy
    @crossword.destroy

    respond_with @crossword do |format|
      format.js {
        # set the objects needed for rendering index
        @crosswords = Crossword.where :session_token => session[:token]
        redirect_pjax_to :index
      }
    end
  end

end
