module VersionKit

  # This class handles version strings according to the Semantic Versioning
  # Specification.
  #
  # Currently based on Semantic Versioning 2.0.0.
  #
  class Version

    include Comparable

    # @return [Array<String, Fixnum>]
    #
    attr_reader :main_version

    # @return [Array<String, Fixnum>]
    #
    attr_reader :pre_release_version

    # @return [Array<String, Fixnum>]
    #
    attr_reader :build_metadata

    # @param [String, Version, #to_s] version @see version
    #
    def initialize(version)
      version = version.to_s.strip

      unless self.class.valid?(version)
        raise ArgumentError, "Malformed version string `#{version}`"
      end

      parts = version.scan(/[^-+]+/)
      @main_version = split_identifiers(parts[0])
      @pre_release_version = split_identifiers(parts[1])
      @build_metadata = split_identifiers(parts[2])
    end

    public

    # @!group Class methods
    #-------------------------------------------------------------------------#

    # @return [Version]
    #
    def self.lenient_new(version)
      new(normalize(version))
    end

    def self.normalize(version)
      version = version.strip.to_s
      version << ".0" if version  =~ /\A[0-9]+\Z/
      version << ".0" if version  =~ /\A[0-9]+\.[0-9]+\Z/
      version
    end

    # @return [RegEx] The regular expression to use to validate a string
    #         representation of a version.
    #
    # rubocop:disable LineLength,
    #
    VERSION_PATTERN = /\A
     [0-9]+\.[0-9]+\.[0-9]+           (?# Main version: Three dot-separated numeric identifiers. )
     ([-][0-9a-z-]+(\.[0-9a-z-]+)*)?  (?# Pre-release Version: Hyphen, followed by any combination of digits, letters, or hyphens separated by periods. )
     ([+][0-9a-z-]+(\.[0-9a-z-]+)*)?  (?# Build Metadata: Plus sign, followed by any combination of digits, letters, or hyphens separated by periods. )
    \Z/xi
    #
    # rubocop:enable LineLength,

    # @return [Bool] Whether a string representation of a version is can be
    #         accepted by this class. This comparison is much more lenient than
    #         the requirements described in the SemVer specification to support
    #         the diversity of versioning practices found in practice.
    #
    def self.valid?(string_reppresentation)
      !(string_reppresentation.to_s =~ VERSION_PATTERN).nil?
    end

    public

    # @!group Object methods
    #-------------------------------------------------------------------------#

    # @return [String] The string representation of the version.
    #
    def to_s
      version_to_string(main_version, pre_release_version, build_metadata)
    end

    # @return [String] a string representation suitable for debugging.
    #
    def inspect
      "<#{self.class} #{to_s}>"
    end

    def ==(other)
      to_s == other.to_s
    end

    # Returns whether a hash should consider equal two versions for being used
    # as a key. To be considered equal versions should be specified with the
    # same precision (i.e. `'1.0' != '1.0.0'`)
    #
    # @param  [Object] The object to compare.
    #
    # @return [Bool] whether a hash should consider other as an equal key to
    #         the instance.
    #
    def eql?(other)
      self.class == other.class && to_s == other.to_s
    end

    # @return [Fixnum] The hash value for this instance.
    #
    def hash
      to_s.hash
    end

    # Compares the instance to another version to determine how it sorts.
    #
    # @param  [Object] The object to compare.
    #
    # @return [Fixnum] -1 means self is smaller than other. 0 means self is
    #         equal to other. 1 means self is bigger than other.
    # @return [Nil] If the two objects could not be compared.
    #
    def <=>(other)
      return nil unless other.class == self.class

      main_version.each_with_index do |identifier, index|
        comparison = identifier <=> other.main_version[index]
        return comparison if comparison != 0
      end

      if self.pre_release? && !other.pre_release?
        return -1
      elsif !self.pre_release? && other.pre_release?
        return 1
      elsif !self.pre_release? && !other.pre_release?
        return 0
      end

      pre_release_identifiers_count =
        [pre_release_version.count, other.pre_release_version.count].min

      pre_release_identifiers_count.times do |index|
        self_identifier = pre_release_version[index]
        othr_identifier = other.pre_release_version[index]

        if !self_identifier.is_a?(String) && othr_identifier.is_a?(String)
          return -1
        elsif self_identifier.is_a?(String) && !othr_identifier.is_a?(String)
          return 1
        else
          comparison = self_identifier <=> othr_identifier
          return comparison if comparison != 0
        end
      end

      if pre_release_version.count < other.pre_release_version.count
        return -1
      elsif pre_release_version.count > other.pre_release_version.count
        return 1
      end

      0
    end

    public

    # @!group Semantic Versioning
    #-------------------------------------------------------------------------#

    # @return [Fixnum] The SemVer major identifier.
    #
    def major
      main_version[0]
    end

    # @return [Fixnum] The SemVer minor identifier.
    #
    def minor
      main_version[1]
    end

    # @return [Fixnum] The SemVer patch identifier.
    #
    def patch
      main_version[2]
    end

    # @return [Boolean] Indicates whether or not the version is a pre-release
    #         version.
    #
    # @note   Pre-release version contain a hyphen and/or a letter.
    #
    def pre_release?
      !pre_release_version.nil?
    end

    # @return [Version] The version stripped of any pre-release segment.
    #
    def release_version
      release_string = version_to_string(main_version)
      self.class.new(release_string)
    end

    # @return [String] The optimistic requirement (`~>`) expected to preserve
    #         backwards compatibility.
    #
    def optimistic_recommendation
      if major == 0
        "~> #{version_to_string(main_version[0..2])}"
      else
        "~> #{version_to_string(main_version[0..1])}"
      end
    end

    public

    # @!group Next Versions
    #-------------------------------------------------------------------------#

    # @return [Version]
    #
    def next_major
      new_main_version = [main_version[0].succ, 0, 0]
      Version.new(version_to_string(new_main_version))
    end

    # @return [Version]
    #
    def next_minor
      new_main_version = [main_version[0], main_version[1].succ, 0]
      Version.new(version_to_string(new_main_version))
    end

    # @return [Version]
    #
    def next_patch
      new_main_version =
        [main_version[0], main_version[1], main_version[2].succ]
      Version.new(version_to_string(new_main_version))
    end

    # @return [Version]
    # @return [Nil]
    #
    def next_pre_release
      return nil unless pre_release_version
      new_pre_release_version = []

      pre_release_version.each do |identifier|
        new_identifier = nil
        if identifier.is_a?(Fixnum)
          new_identifier = identifier.succ
        else
          buffer = ""
          did_bump = false
          identifier.scan(/[0-9]+|[a-z]+/i).map do |segment|
            if /^\d+$/ =~ segment
              if did_bump
                buffer << segment
              else
                buffer << (segment.to_i.succ).to_s
                did_bump = true
              end
            else
              buffer << segment
            end
          end
          if did_bump
            new_identifier = buffer
          end
        end

        if new_identifier
          new_pre_release_version << new_identifier
          break
        else
          new_pre_release_version << identifier
        end
      end

      return nil unless pre_release_version != new_pre_release_version
      Version.new(version_to_string(main_version, new_pre_release_version))
    end

    # @return [Array<Version>]
    #
    def next_versions
      @next_versions ||=
        [next_major, next_minor, next_patch, next_pre_release].compact
    end

    # @return [Bool]
    #
    def valid_next_version?(version)
      next_versions.map(&:to_s).include?(version.to_s)
    end

    def bump(component)
      if component <= 0
        next_major
      elsif component == 1
        next_minor
      else
        next_patch
      end
    end

    private

    # @!group Private Helpers
    #-------------------------------------------------------------------------#

    # @return [Array<String,Fixnum>]
    #
    def split_identifiers(version_part)
      if version_part
        version_part.split(".").map do |identifier|
          if identifier =~ /\A[0-9]+\Z/
            identifier.to_i
          else
            identifier
          end
        end
      end
    end

    # @return [Array<String,Fixnum>]
    #
    def segments_from_string(string)
      string.scan(/[0-9]+|[a-z]+/i).map do |segment|
        if /^\d+$/ =~ segment
          segment.to_i
        else
          segment
        end
      end
    end

    # @return [String]
    #
    def version_to_string(main_version,
                          pre_release_version = nil,
                          build_metadata = nil)
      result = main_version.join(".")

      if pre_release_version && pre_release_version.count > 0
        result << "-" << pre_release_version.join(".")
      end

      if build_metadata && build_metadata.count > 0
        result << "+" << build_metadata.join(".")
      end

      result
    end

    #-------------------------------------------------------------------------#

  end
end
