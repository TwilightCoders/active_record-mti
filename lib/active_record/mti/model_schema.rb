module ActiveRecord
  module MTI
    module ModelSchema

      def self.prepended(base)
        base.extend(ClassMethods)
      end

      module ClassMethods
        # Computes and returns a table name according to default conventions.
        def compute_table_name
          if self != base_class
            # Nested classes are prefixed with singular parent table name.
            if superclass < Base && !superclass.abstract_class?
              contained = superclass.table_name
              contained = contained.singularize if superclass.pluralize_table_names
              contained += '/'
            end

            potential_table_name = "#{full_table_name_prefix}#{contained}#{decorated_table_name(name)}#{full_table_name_suffix}"

            if check_inheritance_of(potential_table_name)
              potential_table_name
            else
              superclass.table_name
            end
          else
            super
          end
        end

        def full_table_name_prefix #:nodoc:
          super
        rescue NoMethodError
          full_table_name_rescue(:table_name_prefix)
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
