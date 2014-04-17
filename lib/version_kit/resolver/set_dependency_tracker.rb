
module VersionKit
  class Resolver
    #
    #
    #
    class SetDependencyTracker
      attr_accessor :name
      attr_accessor :versions
      attr_accessor :dependencies_by_requirer_name

      def initialize(name, versions)
        @name = name
        @versions = versions
        @dependencies_by_requirer_name
      end

      # Updates the versions
      # @return [Bool]
      #
      def add_dependency(dependency, dependent_name)
        store_dependency(dependency, dependent_name)
        self.versions = versions.select { |v| dependency.match?(name, v) }
        if versions.empty?
          false
        else
          true
        end
      end

      def failure_message
        message = "Unable to satisfy the following requirements:\n"
        dependencies_by_requirer_name.each do |name, dependencies|
          dependencies.each do |dep|
            message << "- `#{dep}` required by `#{name}`"
          end
        end
      end

      private

      #-----------------------------------------------------------------------#

      def store_dependency(dependency, dependent_name)
        dependencies_by_requirer_name[dependent_name] ||= []
        dependencies_by_requirer_name[dependent_name] << dependency
      end

      #-----------------------------------------------------------------------#
    end
  end
end
