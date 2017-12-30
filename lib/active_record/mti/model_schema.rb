module ActiveRecord
  module MTI
    module ModelSchema

      def self.prepended(base)
        base.extend(ClassMethods)
      end

      module ClassMethods
        # Computes and returns a table name according to default conventions.
        def compute_table_name
          if not_base_model?

            warned = false

            table_name_parts = [
              full_table_name_prefix,
              nil, # Placeholder for contained_table_name (used later)
              decorated_table_name(name),
              full_table_name_suffix
            ]

            not_nested_table_name_candidate = table_name_parts.join

            if ActiveRecord::MTI.configuration.table_name_nesting
              table_name_parts[1] = contained_table_name if ActiveRecord::MTI.configuration.table_name_nesting
              nested_table_name_candidate = table_name_parts.join
              if check_inheritance_of(nested_table_name_candidate)
                return nested_table_name_candidate
              else
                warned = true
                ActiveRecord::MTI.logger.warn(<<-WARN.squish)
                  Couldn't find table definition '#{nested_table_name_candidate}' for #{name}.
                WARN
              end
            end

            if check_inheritance_of(not_nested_table_name_candidate)
              if warned
                ActiveRecord::MTI.logger.warn(<<-WARN.squish)
                  Found table definition '#{not_nested_table_name_candidate}' for #{name}.
                  Recommended explicitly setting table_name for this model if you're diviating from convention.
                WARN
              end
              not_nested_table_name_candidate
            else
              if warned
                ActiveRecord::MTI.logger.warn(<<-WARN.squish)
                  Falling back on superclass (#{superclass.name}) table definition '#{superclass.table_name}' for #{name}.
                  Recommended explicitly setting table_name for this model if you're diviating from convention.
                WARN
              end
              superclass.table_name
            end
          else
            super
          end
        end

        def not_base_model?
          self != base_class &&
          superclass < Base &&
          !superclass.abstract_class?
        end

        def contained_table_name
          contained_parent_table_name + ActiveRecord::MTI.configuration.nesting_seperator
        end

        def contained_parent_table_name
          if ActiveRecord::MTI.configuration.singular_parent
            superclass.table_name.singularize
          else
            superclass.table_name
          end
        end

        def full_table_name_suffix #:nodoc:
          super
        rescue NoMethodError
          full_table_name_rescue(:table_name_suffix)
        end

        private

        def full_table_name_rescue(which)
          (parents.detect{ |p| p.respond_to?(which) } || self).send(which)
        end

        # Guesses the table name, but does not decorate it with prefix and suffix information.
        def decorated_table_name(class_name = base_class.name)
          super
        rescue NoMethodError
          table_name = class_name.to_s.underscore
          pluralize_table_names ? table_name.pluralize : table_name
        end
      end

    end
  end
end
