class CrosswordsController < ApplicationController

  respond_to :html
  before_filter :find_crossword, :only => [:show, :destroy]

  def index
    tokens = [session[:token]]
    tokens << current_authentication.token if current_authentication
    @crosswords = Crossword.where :session_token.in => tokens.uniq

    @crossword  = Crossword.new
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
    @crossword = Crossword.new
    respond_with @crossword
  end

  def create
    @crossword = Crossword.new(params[:crossword])
    @crossword.session_token = session[:token]
    @crossword.save

    respond_with @crossword
  end

  def destroy
    @crossword.destroy

    respond_with :crosswords
  end

  protected

  def find_crossword
    @crossword = Crossword.where(:slug => params[:id]).first
    raise Mongoid::Errors::DocumentNotFound.new(Crossword,
      :slug => params[:id]) if @crossword.nil?
  end

end
