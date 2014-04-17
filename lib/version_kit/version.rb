require 'version_kit/version/helper'

module VersionKit
  # This class handles version strings according to the Semantic Versioning
  # Specification.
  #
  # Currently based on Semantic Versioning 2.0.0.
  #
  # Example version: 1.2.3-rc.1+2014.01.01
  #
  # Glossary:
  #
  # - version: a string representing a specific release of a software.
  # - component: a version can have 3 components the number (1.2.3), the
  #   pre-release metadata (rc.1), and the Build component (2014.01.01).
  # - element: each component in turn is composed by multiple elements
  #   separated by a dot (like 1, 2, or 01).
  # - bumping: the act of increasing by a single unit one element of the
  #   version.
  #
  class Version
    # @return [RegEx] The regular expression to use to validate a string
    #         representation of a version.
    #
    # The components have the following characteristics:
    #
    # - Number component: Three dot-separated numeric elements.
    # - Pre-release component: Hyphen, followed by any combination of digits,
    #   letters, or hyphens separated by periods.
    # - Build component: Plus sign, followed by any combination of digits,
    #   letters, or hyphens separated by periods.
    #
    VERSION_PATTERN = /\A
      [0-9]+\.[0-9]+\.[0-9]+           (?# Number component)
      ([-][0-9a-z-]+(\.[0-9a-z-]+)*)?  (?# Pre-release component)
      ([+][0-9a-z-]+(\.[0-9a-z-]+)*)?  (?# Build component)
    \Z/xi

    include Comparable

    # @return [Array<Fixnum>] The elements of the number component of the
    #         version.
    #
    attr_reader :number_component

    # @return [Array<String, Fixnum>] The elements of the pre-release component
    #         of the version.
    #
    attr_reader :pre_release_component

    # @return [Array<String, Fixnum>] The elements of the build component of
    #         the version.
    #
    attr_reader :build_component

    # @param  [#to_s] version
    #         Any representation of a version convertible to a string.
    #
    def initialize(version)
      version = version.to_s.strip

      unless self.class.valid?(version)
        raise ArgumentError, "Malformed version string `#{version}`"
      end

      parts = version.scan(/[^-+]+/)
      @number_component = split_component(parts[0])
      @pre_release_component = split_component(parts[1])
      @build_component = split_component(parts[2])
    end

    # @!group Class methods
    #-------------------------------------------------------------------------#

    # @return [Version]
    #
    def self.lenient_new(version)
      new(normalize(version))
    end

    # @return [String]
    #
    def self.normalize(version)
      version = version.strip.to_s
      version << '.0' if version  =~ /\A[0-9]+\Z/
      version << '.0' if version  =~ /\A[0-9]+\.[0-9]+\Z/
      version
    end

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
      result = number_component.join('.')

      if pre_release_component.count > 0
        result << '-' << pre_release_component.join('.')
      end

      if build_component.count > 0
        result << '+' << build_component.join('.')
      end

      result
    end

    # @return [String] a string representation suitable for debugging.
    #
    def inspect
      "<#{self.class} #{self}>"
    end

    # @return [Bool]
    #
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

      number_component.each_with_index do |element, index|
        comparison = element <=> other.number_component[index]
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
        [pre_release_component.count, other.pre_release_component.count].min

      pre_release_identifiers_count.times do |index|
        self_identifier = pre_release_component[index]
        othr_identifier = other.pre_release_component[index]

        if !self_identifier.is_a?(String) && othr_identifier.is_a?(String)
          return -1
        elsif self_identifier.is_a?(String) && !othr_identifier.is_a?(String)
          return 1
        else
          comparison = self_identifier <=> othr_identifier
          return comparison if comparison != 0
        end
      end

      if pre_release_component.count < other.pre_release_component.count
        return -1
      elsif pre_release_component.count > other.pre_release_component.count
        return 1
      end

      0
    end

    public

    # @!group Semantic Versioning
    #-------------------------------------------------------------------------#

    # @return [Fixnum] The SemVer major version.
    #
    def major_version
      number_component[0]
    end

    # @return [Fixnum] The SemVer minor version.
    #
    def minor
      number_component[1]
    end

    # @return [Fixnum] The SemVer patch version.
    #
    def patch
      number_component[2]
    end

    # @return [Boolean] Indicates whether or not the version is a pre-release
    #         version.
    #
    def pre_release?
      !pre_release_component.empty?
    end

    # @return [Version] The version stripped of any pre-release or build
    #         metadata.
    #
    def release_version
      self.class.new(number_component.join('.'))
    end

    # @return [String] The version suggested for the optimistic requirement
    # (`~>`) which, according to SemVer, preserves backwards compatibility.
    #
    def optimistic_recommendation
      if major_version == 0
        "~> #{number_component[0..2].join('.')}"
      else
        "~> #{number_component[0..1].join('.')}"
      end
    end

    private

    # @!group Private Helpers
    #-------------------------------------------------------------------------#

    # Splits a component to the elements separated by a dot in an array
    # converting the ones composed only by digits to a number.
    #
    # @param  [String] component
    #         The component to split in elements.
    #
    # @return [Array<String,Fixnum>] The list of the elements of the component.
    #
    def split_component(component)
      if component
        component.split('.').map do |element|
          if element =~ /\A[0-9]+\Z/
            element.to_i
          else
            element
          end
        end
      else
        []
      end
    end
  end
end
