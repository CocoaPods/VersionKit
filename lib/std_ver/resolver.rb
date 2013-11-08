module StdVer

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
        deps = find_dependency_specs(group_name, dependencies, group, depth = 0)
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
        unless success
          update_base
          restart
        else
          result
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
          raise "Unable to resolve"
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
        if ((iteration_counter % iteration_rate) == 0)
          delegated.did_perform_progress
        end
      end
    end

    #-------------------------------------------------------------------------#

  end
end

#--------------------------------------------------------------------------------

module Bundler
  class Resolver

    def resolve(reqs, activated, depth = 0)
      # If the requirements are empty, then we are in a success state. Aka, all
      # gem dependencies have been resolved.
      safe_throw :success, successify(activated) if reqs.empty?


      reqs = reqs.sort_by do |a|
        [ activated[a.name] ? 0 : 1,
          a.requirement.prerelease? ? 0 : 1,
          @errors[a.name]   ? 0 : 1,
          activated[a.name] ? 0 : @gems_size[a] ]
      end



      activated = activated.dup

      # Pull off the first requirement so that we can resolve it
      current = reqs.shift

      $stderr.puts "#{' ' * depth}#{current}" if ENV['DEBUG_RESOLVER_TREE']

      debug { "Attempting:\n  #{current}"}

      # Check if the gem has already been activated, if it has, we will make sure
      # that the currently activated gem satisfies the requirement.
      existing = activated[current.name]
      if existing || current.name == 'bundler'
        if current.requirement.satisfied_by?(existing.version)

        else
          debug { "    * [FAIL] Already activated" }
          @errors[existing.name] = [existing, current]
          debug { current.required_by.map {|d| "      * #{d.name} (#{d.requirement})" }.join("\n") }
          # debug { "    * All current conflicts:\n" + @errors.keys.map { |c| "      - #{c}" }.join("\n") }
          # Since the current requirement conflicts with an activated gem, we need
          # to backtrack to the current requirement's parent and try another version
          # of it (maybe the current requirement won't be present anymore). If the
          # current requirement is a root level requirement, we need to jump back to
          # where the conflicting gem was activated.
          parent = current.required_by.last
          # `existing` could not respond to required_by if it is part of the base set
          # of specs that was passed to the resolver (aka, instance of LazySpecification)
          parent ||= existing.required_by.last if existing.respond_to?(:required_by)
          # We track the spot where the current gem was activated because we need
          # to keep a list of every spot a failure happened.
          if parent && parent.name != 'bundler'
            debug { "    -> Jumping to: #{parent.name}" }
            required_by = existing.respond_to?(:required_by) && existing.required_by.last
            safe_throw parent.name, required_by && required_by.name
          else
            # The original set of dependencies conflict with the base set of specs
            # passed to the resolver. This is by definition an impossible resolve.
            raise version_conflict
          end
        end
      else
        # There are no activated gems for the current requirement, so we are going
        # to find all gems that match the current requirement and try them in decending
        # order. We also need to keep a set of all conflicts that happen while trying
        # this gem. This is so that if no versions work, we can figure out the best
        # place to backtrack to.
        conflicts = Set.new

        # Fetch all gem versions matching the requirement
        matching_versions = search(current)

        # If we found no versions that match the current requirement
        if matching_versions.empty?
          # If this is a top-level Gemfile requirement
          if current.required_by.empty?
            if base = @base[current.name] and !base.empty?
              version = base.first.version
              message = "You have requested:\n" \
                    "  #{current.name} #{current.requirement}\n\n" \
                    "The bundle currently has #{current.name} locked at #{version}.\n" \
                    "Try running `bundle update #{current.name}`"
            elsif current.source
              name = current.name
              versions = @source_requirements[name][name].map { |s| s.version }
              message  = "Could not find gem '#{current}' in #{current.source}.\n"
              if versions.any?
                message << "Source contains '#{name}' at: #{versions.join(', ')}"
              else
                message << "Source does not contain any versions of '#{current}'"
              end
            else
              message = "Could not find gem '#{current}' "
              if @index.source_types.include?(Bundler::Source::Rubygems)
                message << "in any of the gem sources listed in your Gemfile."
              else
                message << "in the gems available on this machine."
              end
            end
            raise GemNotFound, message
          # This is not a top-level Gemfile requirement
          else
            @errors[current.name] = [nil, current]
          end
        end

        matching_versions.reverse_each do |spec_group|
          conflict = resolve_requirement(spec_group, current, reqs.dup, activated.dup, depth)
          conflicts << conflict if conflict
        end

        # We throw the conflict up the dependency chain if it has not been
        # resolved (in @errors), thus avoiding branches of the tree that have no effect
        # on this conflict.  Note that if the tree has multiple conflicts, we don't
        # care which one we throw, as long as we get out safe
        if !current.required_by.empty? && !conflicts.empty?
          @errors.reverse_each do |req_name, pair|
            if conflicts.include?(req_name)
              # Choose the closest pivot in the stack that will affect the conflict
              errorpivot = (@stack & [req_name, current.required_by.last.name]).last
              debug { "    -> Jumping to: #{errorpivot}" }
              safe_throw errorpivot, req_name
            end
          end
        end

        # If the current requirement is a root level gem and we have conflicts, we
        # can figure out the best spot to backtrack to.
        if current.required_by.empty? && !conflicts.empty?
          # Check the current "catch" stack for the first one that is included in the
          # conflicts set. That is where the parent of the conflicting gem was required.
          # By jumping back to this spot, we can try other version of the parent of
          # the conflicting gem, hopefully finding a combination that activates correctly.
          @stack.reverse_each do |savepoint|
            if conflicts.include?(savepoint)
              debug { "    -> Jumping to: #{savepoint}" }
              safe_throw savepoint
            end
          end
        end
      end
    end

    def resolve_requirement(spec_group, requirement, reqs, activated, depth)
      # We are going to try activating the spec. We need to keep track of stack of
      # requirements that got us to the point of activating this gem.
      spec_group.required_by.replace requirement.required_by
      spec_group.required_by << requirement

      activated[spec_group.name] = spec_group
      debug { "  Activating: #{spec_group.name} (#{spec_group.version})" }
      debug { spec_group.required_by.map { |d| "    * #{d.name} (#{d.requirement})" }.join("\n") }

      dependencies = spec_group.activate_platform(requirement.__platform)

      # Now, we have to loop through all child dependencies and add them to our
      # array of requirements.
      debug { "    Dependencies"}
      dependencies.each do |dep|
        next if dep.type == :development
        debug { "    * #{dep.name} (#{dep.requirement})" }
        dep.required_by.replace(requirement.required_by)
        dep.required_by << requirement
        @gems_size[dep] ||= gems_size(dep)
        reqs << dep
      end

      # We create a savepoint and mark it by the name of the requirement that caused
      # the gem to be activated. If the activated gem ever conflicts, we are able to
      # jump back to this point and try another version of the gem.
      length = @stack.length
      @stack << requirement.name
      retval = safe_catch(requirement.name) do
        # try to resolve the next option
        resolve(reqs, activated, depth)
      end

      # clear the search cache since the catch means we couldn't meet the
      # requirement we need with the current constraints on search
      clear_search_cache

      # Since we're doing a lot of throw / catches. A push does not necessarily match
      # up to a pop. So, we simply slice the stack back to what it was before the catch
      # block.
      @stack.slice!(length..-1)
      retval
    end

    def gems_size(dep)
    end

    def clear_search_cache
    end

    # @return [SpecGroup]
    #
    def search(dep)
    end

    def version_conflict
      VersionConflict.new(errors.keys, error_message)
    end

    def gem_message(requirement)
    end

    def error_message
      errors.inject("") do |o, (conflict, (origin, requirement))|

        # origin is the SpecSet of specs from the Gemfile that is conflicted with
        if origin

          o << %{Bundler could not find compatible versions for gem "#{origin.name}":\n}
          o << "  In Gemfile:\n"

          o << gem_message(requirement)
          o << gem_message(origin)

        # origin is nil if the required gem and version cannot be found in any of
        # the specified sources
        else

          # if the gem cannot be found because of a version conflict between lockfile and gemfile,
          # print a useful error that suggests running `bundle update`, which may fix things
          #
          # @base is a SpecSet of the gems in the lockfile
          # conflict is the name of the gem that could not be found
          if locked = @base[conflict].first
            o << "Bundler could not find compatible versions for gem #{conflict.inspect}:\n"
            o << "  In snapshot (Gemfile.lock):\n"
            o << "    #{clean_req(locked)}\n\n"

            o << "  In Gemfile:\n"
            o << gem_message(requirement)
            o << "Running `bundle update` will rebuild your snapshot from scratch, using only\n"
            o << "the gems in your Gemfile, which may resolve the conflict.\n"

          # the rest of the time, the gem cannot be found because it does not exist in the known sources
          else
            if requirement.required_by.first
              o << "Could not find gem '#{clean_req(requirement)}', which is required by "
              o << "gem '#{clean_req(requirement.required_by.first)}', in any of the sources."
            else
              o << "Could not find gem '#{clean_req(requirement)} in any of the sources\n"
            end
          end

        end
        o
      end
    end

    private

  end
end
