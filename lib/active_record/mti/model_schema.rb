module ActiveRecord
  module MTI
    module ModelSchema
      extend ActiveSupport::Concern


      module ClassMethods

        # Computes the table name, (re)sets it internally, and returns it.
        def reset_table_name #:nodoc:
          self.table_name = if abstract_class?
            superclass == Base ? nil : superclass.table_name
          elsif superclass.abstract_class?# || superclass.using_multi_table_inheritance?
            superclass.table_name || compute_table_name
          else
            compute_table_name
          end
        end

        # Computes and returns a table name according to default conventions.
        def compute_table_name
          base = base_class
          if self == base
            # Nested classes are prefixed with singular parent table name.
            if parent < Base && !parent.abstract_class?
              contained = parent.table_name
              contained = contained.singularize if parent.pluralize_table_names
              contained += '_'
            end

            "#{full_table_name_prefix}#{contained}#{undecorated_table_name(name)}#{full_table_name_suffix}"
          elsif uses_mti?

            # Nested classes are prefixed with singular parent table name.
            if superclass < Base && !superclass.abstract_class?
              contained = superclass.table_name
              contained = contained.singularize if superclass.pluralize_table_names
              contained += '/'
            end

            "#{full_table_name_prefix}#{contained}#{decorated_table_name(name)}#{full_table_name_suffix}"
          elsif superclass.uses_mti?
            # STI subclasses always use their superclass' table.
            superclass.table_name
          end
        end

        private

        # Guesses the table name, but does not decorate it with prefix and suffix information.
        def decorated_table_name(class_name = base_class.name)
          table_name = class_name.to_s.underscore
          pluralize_table_names ? table_name.pluralize : table_name
        end

      end
    end
  end
end
