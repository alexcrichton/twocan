module ApplicationHelper

  def page_title
    if @crossword
      @crossword.title + " | TwoCan"
    else
      "TwoCan - Collaborative Crosswords"
    end
  end

end
