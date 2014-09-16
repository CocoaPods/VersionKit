module VersionKit
  #
  #
  class Dependency
    # @return [String] The name
    #
    attr_accessor :name

    # @return [Array<Requirement>]
    #
    attr_accessor :requirement_list

    #
    #
    def initialize(name, requirements)
      @name = name
      @requirement_list = RequirementList.new(requirements)
    end

    #
    #
    def satisfied_by?(candidate_version)
      requirement_list.satisfied_by?(candidate_version)
    end
  end
end
