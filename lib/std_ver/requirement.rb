module StdVer

  #
  #
  class Requirement

    include Comparable

    OPERATORS_LAMBDAS = {
      "="  =>  lambda { |candidate, version| versionify(candidate) == versionify(version) },
      "!=" =>  lambda { |candidate, version| versionify(candidate) != versionify(version) },
      ">"  =>  lambda { |candidate, version| versionify(candidate) >  versionify(version) },
      "<"  =>  lambda { |candidate, version| versionify(candidate) <  versionify(version) },
      ">=" =>  lambda { |candidate, version| versionify(candidate) >= versionify(version) },
      "<=" =>  lambda { |candidate, version| versionify(candidate) <= versionify(version) },
      "~>" =>  lambda { |candidate, version| versionify(candidate) >= versionify(version) && versionify(candidate).release_version < bump(version) }
    }

    # quoted  = OPS.keys.map { |k| Regexp.quote k }.join "|"
    # PATTERN = /\A\s*(#{quoted})?\s*(#{Gem::Version::VERSION_PATTERN})\s*\z/

    attr_reader :operator
    attr_reader :version

    def initialize(string)
      splitted = string.strip.split(' ')
      if splitted.count == 1
        operator = '='
        version = splitted[0]
      else
        operator = splitted[0]
        version = splitted[1]
      end
      version = Version.normalize(version)

      unless OPERATORS_LAMBDAS.include?(operator)
        raise ArgumentError, "Unsupported operator `#{operator}` requirement `#{string}`"
      end

      unless Version.valid?(version)
        raise ArgumentError, "Malformed version `#{version}` for requirement `#{string}`"
      end

      @operator = operator
      @version = version
    end

    def satisfied_by?(candidate_version)
      OPERATORS_LAMBDAS[operator].call(candidate_version, version)
    end


    public

    # @!group Object methods
    #-------------------------------------------------------------------------#

    def to_s
      "#{operator} #{version}"
    end

    def <=> other
      to_s <=> other.to_s
    end

    def hash
      to_s.hash
    end


    private

    # @!group Private Helpers
    #-------------------------------------------------------------------------#

    def self.versionify(string)
      Version.lenient_new(string)
    end

    def self.bump(string)
      main_version = string.scan(/[^-+]+/).first
      identifiers = main_version.split('.').map(&:to_i)
      identifiers.pop if identifiers.size > 1
      identifiers[-1] = identifiers[-1].succ
      versionify(identifiers.join('.'))
    end

    #-------------------------------------------------------------------------#

  end

  class RequirementList

    attr_reader :requirements

    def initialize(requirements = [])
      @requirements = requirements
    end

    def add_requirement(requirement)
      requirements << requirement
      requirements.uniq!
    end

    def satisfied_by?(candidate_version)
      requirements.all? { |requirement| requirement.satisfied_by?(candidate_version) }
    end

  end
end
