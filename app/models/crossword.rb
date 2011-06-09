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

  validate :binary_file_is_valid
  # validates_presence_of :binary_data, :width, :height, :solution

  attr_accessor :binary_file

  embeds_many :clues

  def binary_file_is_valid
    return unless @binary_file.present?
    self[:binary_data] = nil

    file   = @binary_file.open
    parser = Parser.new.tap{ |p| p.parse! file.binmode }

    self[:title]     = parser.title
    self[:author]    = parser.author
    self[:copyright] = parser.copyright
    self[:notes]     = parser.notes
    self[:width]     = parser.width
    self[:height]    = parser.height
    self[:solution]  = parser.solution.to_s

    self.clues = parser.clues

    file.rewind
    self[:binary_data] = file.read
  rescue ParseError, ChecksumError, CompatibilityError => e
    errors[:binary_file] << 'is an invalid crossword file.'
  end

  def to_puz
    raise 'Not implemented yet!'
  end

end
