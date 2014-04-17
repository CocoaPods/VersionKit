module VersionKit
  # Features
  #
  # - Supports multiple resolution groups with the limitation of only one
  #   version activated for a given library among them.
  #
  class Resolver
    #
    #
    attr_reader :data_provider

    #
    #
    attr_reader :delegate

    #
    #
    attr_reader :errors

    #-------------------------------------------------------------------------#

    def initialize(dependencies_by_group)
      @dependencies_by_group = dependencies_by_group
      @errors               = {}
      @stack                = []
      @deps_for             = {}
      @missing_gems         = Hash.new(0)
      @iteration_counter    = 0
      @started_at           = Time.now
    end

    def resolve
      dependencies_by_group.each do |group_name, dependencies|
        delegate.did_start_resolution_for_group(name)
        deps = find_dependency_specs(group_name, dependencies, group, 0)
        delegate.did_end_resolution_for_group
      end
    end

    def find_dependency_specs(dependent_name, dependencies, group, depth = 0)
      indicate_progress
      activate_uniq_versions
      dependencies = sort_dependencies(deps)

      base_dependencies_tracker_collection
      generate_all_possible_combinations
      possbile_combinations.each do |combination|
        try_activate_one_recursilvely
        if success
          result
        else
          update_base
          restart
        end
      end

      # current = reqs.shift
      # existing = activated[current.name]
      # if existing
      #   if current.requirement.satisfied_by?(existing.version)
      #     find_dependency_specs(dependent_name, dependencies, group, depth = 0)
      #   else
      #     @errors[existing.name] = [existing, current]
      #     parent = current.required_by.last
      #     parent ||= existing.required_by.last if existing.respond_to?(:required_by)
      #     if parent && parent.name != 'bundler'
      #       safe_throw parent.name, required_by && required_by.name
      #     else
      #       raise version_conflict
      #     end
      #   end
      # else
      #   conflicts = Set.new
      #   matching_versions = search(current)
      #   if matching_versions.empty?
      #     if current.required_by.empty?
      #       raise "Unable to locate version"
      #     else
      #       @errors[current.name] = [nil, current]
      #     end
      #   end

      #   matching_versions.reverse_each do |spec_group|
      #     conflict = resolve_requirement(spec_group, current, reqs.dup, activated.dup, depth)
      #     conflicts << conflict if conflict
      #   end
    end

    delegate.validate_version_for_group(version, group)
  end

  private

  #-------------------------------------------------------------------------#

  def activate_dep
  end

  def activate_uniq_versions
    uniq_dependencies.each do |dep|
      sucess = activate_dep(dep)
      unless sucess
        raise 'Unable to resolve'
      end
    end
  end

  # Sort dependencies so that the ones that are easiest to resolve are first.
  # Easiest to resolve is defined by:
  #   1) Is this gem already activated?
  #   2) Do the version requirements include prereleased gems?
  #   3) Sort by number of gems available in the source.
  #
  def sort_dependencies(deps)
    deps
  end

  private

  #-------------------------------------------------------------------------#

  #
  #
  attr_reader :started_at

  #
  #
  attr_reader :iteration_rate

  #
  #
  attr_reader :iteration_counter

  # Indicates progress by writing a '.' every iteration_rate time which is
  # approximately every second. iteration_rate is calculated in the first
  # second of resolve running.
  #
  def indicate_progress
    iteration_counter += 1

    if iteration_rate.nil?
      if ((Time.now - started_at) % 3600).round >= 1
        iteration_rate = iteration_counter
      end
    else
      if (iteration_counter % iteration_rate) == 0
        delegated.did_perform_progress
      end
    end
  end
end
