module VersionKit
  class Version
    # Identifies the possible next versions from a given one.
    #
    module ComponentsHelper
      # Compares the numerical component with the one of another version.
      #
      # @param  [Version] second
      #         The version to compare against.
      #
      # @return [Fixnum] See #<=>
      #
      def self.compare_numerical_component(first, second)
        first.number_component.each_with_index do |element, index|
          result = element <=> second.number_component[index]
          return result if result != 0
        end
        0
      end

      # Compares the pre-release component with the one of another version.
      #
      # @param  [Version] second
      #         The version to compare against.
      #
      # @return [Fixnum] See #<=>
      #
      def self.compare_pre_release_component(first, second)
        result = (first.pre_release? ? 0 : 1) <=> (second.pre_release? ? 0 : 1)
        return result if result != 0

        first_component = first.pre_release_component
        second_component = second.pre_release_component

        count = [first_component.count, second_component.count].max
        count.times do |index|
          first_value = first_component[index]
          second_value = second_component[index]
          result = compare_pre_release_identifiers(first_value, second_value)
          return result if result != 0
        end
        0
      end

      # Compares two pre-release identifiers.
      #
      # @param  [String,Fixnum] fist
      #         The first identifier to compare.
      #
      # @param  [String,Fixnum] second
      #         The second identifier to compare.
      #
      # @return [Fixnum] See #<=>
      #
      def self.compare_pre_release_identifiers(first, second)
        return -1 if first.nil?
        return +1 if second.nil?

        if first.is_a?(Fixnum) && second.is_a?(Fixnum)
          first.to_i <=> second.to_i
        elsif first.is_a?(Fixnum)
          -1
        elsif second.is_a?(Fixnum)
          +1
        else
          first.to_s <=> second.to_s
        end
      end

      # Splits a component to the elements separated by a dot in an array
      # converting the ones composed only by digits to a number.
      #
      # @param  [String] component
      #         The component to split in elements.
      #
      # @return [Array<String,Fixnum>] The list of the elements of the component.
      #
      def self.split_component(component)
        if component
          component.split('.').map do |identifier|
            if identifier =~ /\A[0-9]+\Z/
              identifier.to_i
            else
              identifier
            end
          end
        else
          []
        end
      end
    end
  end
end
