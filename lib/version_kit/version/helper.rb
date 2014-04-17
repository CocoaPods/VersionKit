module VersionKit
  class Version
    # Identifies the possible next versions from a given one.
    #
    module Helper
      # Bumps the component at the given index
      # @param  [Version, #to_s] version
      # @param  [#to_i] component
      # @return [Version]
      #
      def self.bump(version, index)
        index = index.to_i
        unless (0..2).include?(index)
          raise ArgumentError, "Unsupported index `#{index}`"
        end

        version = coherce_version(version)
        components = version.number_component[0..index]
        components[index] = components[index].succ
        Version.lenient_new(components.join('.'))
      end

      # @param  [Version, #to_s] version
      # @return [Version]
      #
      def self.next_major(version)
        bump(version, 0)
      end

      # @param  [Version, #to_s] version
      # @return [Version]
      #
      def self.next_minor(version)
        bump(version, 1)
      end

      # @param  [Version, #to_s] version
      # @return [Version]
      #
      def self.next_patch(version)
        bump(version, 2)
      end

      # @param  [Version, #to_s] version
      # @return [Version]
      # @return [Nil]
      #
      def self.next_pre_release(version)
        version = coherce_version(version)
        return nil unless version.pre_release_component
        original = version.pre_release_component.join('.')
        index  = original.index(/\d/)
        if index
          new = original[0...index] + original.scan(/\d/).first.succ
          string = "#{version.number_component.join('.')}-#{new}"
          Version.new(string)
        end
      end

      # @param  [Version, #to_s] version
      # @return [Array<Version>] All the possible versions the given one
      #         might evolve in.
      #
      def self.next_versions(version)
        version = coherce_version(version)
        [
          next_major(version),
          next_minor(version),
          next_patch(version),
          next_pre_release(version)
        ].compact
      end

      # @param  [Version, #to_s] version
      # @param  [Version, #to_s] candidate
      # @return [Bool]
      #
      def self.valid_next_version?(version, candidate)
        version = coherce_version(version)
        candidate = coherce_version(candidate)
        next_versions(version).include?(candidate)
      end

      # @group Private Helpers

      # @param  [Version, #to_s] version
      # @return [Version]
      #
      def self.coherce_version(version)
        if version.is_a?(Version)
          version
        else
          Version.lenient_new(version)
        end
      end
    end
  end
end
