class Crossword
  include Mongoid::Document

  field :title
  field :author
  field :copyright
  field :notes
  field :binary_data, :type => BSON::Binary
  field :width, :type => Integer
  field :height, :type => Integer
  field :solution
  field :clues, :type => Array
  field :slug
  field :session_token

  index :slug

  before_validation :set_slug_if_blank
  validate :crossword_file_is_valid
  validates_uniqueness_of :slug

  attr_accessible :crossword_file
  attr_accessor :crossword_file

  embeds_many :clues

  def self.find_by_slug! slug
    where(:slug => slug).first or raise Mongoid::Errors::DocumentNotFound.new(
      self, :slug => slug)
  end

  def binary_data= data
    super BSON::Binary.new(data)
  end

  def crossword_file_is_valid
    if new_record? && @crossword_file.nil?
      errors[:crossword_file] << 'is required'
      return
    end
    self[:binary_data] = nil

    file   = @crossword_file.respond_to?(:open) ?
      @crossword_file.open :
      @crossword_file
    parser = Crosswords::Parser.new
    parser.parse! file

    self[:title]     = parser.title
    self[:author]    = parser.author
    self[:copyright] = parser.copyright
    self[:notes]     = parser.notes
    self[:width]     = parser.width
    self[:height]    = parser.height
    self[:solution]  = parser.solution.to_s

    self.clues = parser.clues

    file.rewind
    self.binary_data = file.read
  rescue Crosswords::ParseError, Crosswords::ChecksumError => e
    errors[:crossword_file] << 'is an invalid crossword file.'
  end

  alias :to_puz :binary_data
  alias :to_param :slug

  protected

  def set_slug_if_blank
    self[:slug] ||= SecureRandom.hex(10)
  end

end
