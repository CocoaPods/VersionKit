module StdVer
  class Resolver

    # Describes a constraint on the acceptable elements of a list of versions.
    # The only relevant method for this class is the `#satisfied_by?` method.
    #
    module DataProvider

      # @return [Array<Dependency>]
      #
      def dependencies_of(name, version)
        Dependency.new('LibA', '1.0')
      end

      # @return [Array<String>]
      #
      def available_versions(name)
        ['1.0', '2.0']
      end

    end
  end
end


