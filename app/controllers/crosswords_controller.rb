class CrosswordsController < ApplicationController

  respond_to :html

  def index
    @crosswords = Crossword.all
    respond_with @crosswords
  end

  def show
    @crossword = Crossword.find(params[:id])

    respond_with @crossword do |format|
      format.json
    end
  end

  def new
    @crossword = Crossword.new
    respond_with @crossword
  end

  def edit
    @crossword = Crossword.find(params[:id])
    respond_with @crossword
  end

  def create
    @crossword = Crossword.new(params[:crossword])
    @crossword.save

    respond_with @crossword
  end

  def update
    @crossword = Crossword.find(params[:id])
    @crossword.update_attributes params[:crossword]

    respond_with @crossword
  end

  def destroy
    @crossword = Crossword.find(params[:id])
    @crossword.destroy

    respond_with :crosswords
  end

end
