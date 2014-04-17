require 'version_kit/version/helper'
require 'version_kit/version/components_helper'

module VersionKit
  # Model class which provides support for versions according to the [Semantic
  # Versioning Specification](http://semver.org).
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
  # - identifier: each component in turn is composed by multiple identifier
  #   separated by a dot (like 1, 2, or 01).
  # - bumping: the act of increasing by a single unit one identifier of the
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

    # @return [Array<Array<Fixnum,String>>]
    #
    attr_reader :components

    # @param  [#to_s] version
    #         Any representation of a version convertible to a string.
    #
    def initialize(version)
      version = version.to_s.strip

      unless self.class.valid?(version)
        raise ArgumentError, "Malformed version string `#{version}`"
      end

      component_strings = version.scan(/[^-+]+/)
      @components = (0..2).map do |index|
        ComponentsHelper.split_component(component_strings[index])
      end
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

    # @!group Semantic Versioning
    #-------------------------------------------------------------------------#

    # @return [Array<Fixnum>] The elements of the number component of the
    #         version.
    #
    def number_component
      @components[0]
    end

    # @return [Array<String, Fixnum>] The elements of the pre-release component
    #         of the version.
    #
    def pre_release_component
      @components[1]
    end

    # @return [Array<String, Fixnum>] The elements of the build component of
    #         the version.
    #
    def build_component
      @components[2]
    end

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
    # @note   From semver.org:
    #
    #         - Major, minor, and patch versions are always compared
    #           numerically.
    #         - When major, minor, and patch are equal, a pre-release version
    #           has lower precedence than a normal version.
    #         - Precedence for two pre-release versions with the same major,
    #           minor, and patch version MUST be determined by comparing each
    #           dot separated identifier from left to right until a difference
    #           is found as follows: identifiers consisting of only digits are
    #           compared numerically and identifiers with letters or hyphens
    #           are compared lexically in ASCII sort order. Numeric identifiers
    #           always have lower precedence than non-numeric identifiers. A
    #           larger set of pre-release fields has a higher precedence than a
    #           smaller set, if all of the preceding identifiers are equal.
    #         - Build metadata SHOULD be ignored when determining version
    #           precedence.
    #
    def <=>(other)
      return nil unless other.class == self.class

      result = ComponentsHelper.compare_numerical_component(self, other)
      return result if result != 0

      result = ComponentsHelper.compare_pre_release_component(self, other)
      return result if result != 0

      0
    end
  end
end
