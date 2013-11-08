module StdVer
  class Resolver

    # As requests to the data provider are idem potent this class caches them
    # freeing clients from this logic.
    #
    module DataProviderCache

      attr_reader :data_provider

      def initialize(data_proivder)
        @data_proivder = data_proivder
      end

      #-----------------------------------------------------------------------#

      # @return [Array<Dependency>]
      #
      def dependencies_of(name, version)
        @data_proivder.dependencies_of(name, version)
      end

      # @return [Array<String>]
      #
      def available_versions(name)
        @data_proivder.available_versions(name)
      end

      #-----------------------------------------------------------------------#

      # @return [Array<String>]
      #
      def libs_with_unique_versions(names)
        names.select do |name|
          available_versions(name).count == 1
        end
      end

      #-----------------------------------------------------------------------#

    end
  end
end
