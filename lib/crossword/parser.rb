class Crossword
  attr_accessor :width, :height, :solution, :progress, :title, :author,
    :copyright, :clues, :sections, :notes

  class ParseError < StandardError; end
  class ChecksumError < StandardError; end
  class CompatibilityError < StandardError; end

  class Grid
    def initialize crossword
      @crossword = crossword
    end
  end

  class Section
    attr_accessor :title, :length, :cksum, :data

    def self.parse! io
      Section.new.tap do |s|
        s.title  = io.read(0x4)
        s.length = io.read(0x2).unpack('v').first
        s.cksum  = io.read(0x2).unpack('v').first
        s.data   = io.read(s.length)

        raise ParseError unless io.readbyte == 0
      end
    end
  end

  class Parser
    # Parse the given IO stream. For the specifics on the format of a crossword,
    # see http://code.google.com/p/puz/wiki/FileFormat
    # 
    # @param [IO, String] io the IO stream that is readable or a string that is
    #    a crossword file
    # 
    # @raise [ParseError] if the stream given is not a valid crossword file
    # @raise [ChecksumError] if the checksums given in the stream do not match
    # @raise [CompatibilityError] if the version of the crossword file is not
    #     supported yet by this class
    def parse! io
      io = StringIO.new(io) if io.is_a?(String)

      @cksum    = io.read(0x2).unpack('v').first
      magic     = io.read(0xc).unpack('Z11').first
      raise ParseError if magic != 'ACROSS&DOWN'

      @cib_cksum = io.read(0x2).unpack('v').first
      @masked_low_cksum  = io.read(0x4).unpack('C4')
      @masked_high_cksum = io.read(0x4).unpack('C4')

      version = io.read(0x4).unpack('Z3').first
      raise CompatibilityError.new('Must be v1.2') unless version == '1.2'

      _garbage   = io.read(0x2)
      @sol_cksum = io.read(0x2).unpack('v').first
      _garbage   = io.read(0xc)
      @width     = io.read(0x1).unpack('C').first
      @height    = io.read(0x1).unpack('C').first
      num_clues  = io.read(0x2).unpack('v').first
      _garbage   = io.read(0x2)
      @scrambled = io.read(0x2).unpack('v').first

      solution = Grid.new(self) { |g| g.parse! io }
      progress = Grid.new(self) { |g| g.parse! io }

      io.set_encoding('iso-8859-1')
      @title     = io.readline("\x00").chomp("\x00")
      @author    = io.readline("\x00").chomp("\x00")
      @copyright = io.readline("\x00").chomp("\x00")

      @clues = []
      num_clues.times { @clues << io.readline("\x00").chomp("\x00") }
      @notes = io.readline("\x00").chomp("\x00")

      @sections = []
      @sections << Section.parse!(io) while !io.eof?

      validate io

      self[:width]  = @width
      self[:height] = @height
      self[:solution] = solution.to_s
      self[:clues] = @clues.map{ |c| c.encode('utf-8') }
    end

    protected

    def parse_saved_data
      parse! binary_file if binary_file.present?
    end

    # Validates checksums of an IO. Assumes #parse! has been previously called.
    # For the details on the checksums, see the same website mentioned in
    # #parse!
    # 
    # @param [IO] io the I/O object which is read from
    def validate io
      # Initially validate the CIB checksum
      io.seek 0x2c # start of the CIB header
      raise ChecksumError if @cib_cksum != cksum(io, 8)

      # Now validate the entire puzzle checksum
      ck = @cib_cksum
      ck = cksum io, @width * @height, ck # solution
      ck = cksum io, @width * @height, ck # grid
      ck = cksum io, @title.length + 1, ck
      ck = cksum io, @author.length + 1, ck
      ck = cksum io, @copyright.length + 1, ck

      @clues.each_with_index { |c, i|
        ck = cksum io, c.length, ck
        raise ParseError if io.getbyte != 0
      }

      io.readline("\x00") # skip note

      raise ChecksumError if ck != @cksum

      # Now validate each of the checksums of the sections
      @sections.each { |section|
        io.seek 0x8, IO::SEEK_CUR # skip title, length, checksum
        raise ChecksumError if cksum(io, section.length) != section.cksum
        raise ParseError unless io.readbyte == 0
      }

      # Now finally validate the masked checksums
      io.seek 0x34 # Start of the solution grids
      c_sol  = cksum io, @width * @height
      c_grid = cksum io, @width * @height

      c_part = cksum io, @title.length + 1
      c_part = cksum io, @author.length + 1, c_part
      c_part = cksum io, @copyright.length + 1, c_part
      @clues.each_with_index { |c, i|
        c_part = cksum io, c.length, c_part
        raise ParseError if io.getbyte != 0
      }

      raise ChecksumError if \
        @masked_low_cksum[0] != (0x49 ^ (@cib_cksum & 0xff)) ||
        @masked_low_cksum[1] != (0x43 ^ (c_sol & 0xff)) ||
        @masked_low_cksum[2] != (0x48 ^ (c_grid & 0xff)) ||
        @masked_low_cksum[3] != (0x45 ^ (c_part & 0xff)) ||
        @masked_high_cksum[0] != (0x41 ^ ((@cib_cksum >> 8) & 0xff)) ||
        @masked_high_cksum[1] != (0x54 ^ ((c_sol >> 8) & 0xff)) ||
        @masked_high_cksum[2] != (0x45 ^ ((c_grid >> 8) & 0xff)) ||
        @masked_high_cksum[3] != (0x44 ^ ((c_part >> 8) & 0xff))
    end

    # Performs a checksum on the I/O over a specified region from whatever the
    # current position of the IO object is
    # 
    # @param [IO] io the I/O object
    # @param [Integer] len the number of bytes to sum
    # @param [Integer] sum the initial value of the checksum
    # 
    # @return [Integer] the checksum of the bytes
    def cksum io, len, sum = 0
      len.times{
        sum = sum & 0x1 == 1 ? (sum >> 1) + 0x8000 : sum >> 1;
        sum += io.readbyte
        sum &= 0xffff
      }

      sum
    end

  end
end