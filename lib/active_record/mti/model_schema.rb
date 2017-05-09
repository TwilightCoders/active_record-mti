module ActiveRecord
  module MTI
    module ModelSchema
      extend ActiveSupport::Concern


      module ClassMethods

        # Computes the table name, (re)sets it internally, and returns it.
        def reset_table_name #:nodoc:
          # binding.pry
          self.table_name = if abstract_class?
            superclass == Base ? nil : superclass.table_name
          elsif superclass.abstract_class? || superclass.using_multi_table_inheritance?
            superclass.table_name || compute_table_name
          else
            compute_table_name
          end
        end

      end
    end
  end
end
