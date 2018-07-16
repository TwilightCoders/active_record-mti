module ActiveRecord
  module MTI
    module Table

      def self.find(klass)
        table = nil
        permute_table_names(klass).each do |table_name|
          puts "trying #{table_name}"
          break if (table = mti_table(table_name))
        end
        table
      end

      private

      def self.mti_table(table_name)
        ::ActiveRecord::MTI.child_tables.find(name: table_name) || ::ActiveRecord::MTI.parent_tables.find(name: table_name)
      end

      def self.base_model?(klass)
        (klass == klass.base_class ||
        klass.superclass == ::ActiveRecord::Base ||
        klass.superclass.abstract_class?) == true
      end

      def self.config
        ::ActiveRecord::MTI.configuration
      end

      def self.table_name(klass)
        table_name = klass.pluralize_table_names ? table_name.pluralize : table_name
        table_name = "#{parent_prefixed(klass)}#{table_name}#{parent_suffixed(klass)}"
        "#{klass.full_table_name_prefix}#{table_name}#{klass.full_table_name_suffix}"
      end

      def self.namespaced(klass_name)
        namespaces = klass_name.split('::')
        left
        while config.namespaced_depth != 1
      end

      # def self.permute_table_names(klass)
      #   namespaces(klass.name).collect do |table_name|
      #     table_name = klass.pluralize_table_names ? table_name.pluralize : table_name
      #     table_name = "#{parent_prefixed(klass)}#{table_name}#{parent_suffixed(klass)}"
      #     "#{klass.full_table_name_prefix}#{table_name}#{klass.full_table_name_suffix}"
      #   end
      # end

      def self.parent_prefixed(klass)
        if !base_model?(klass) && config.table_name_nesting && config.prefix_parent
          parent_name(klass) + config.nesting_seperator
        end
      end

      def self.parent_suffixed(klass)
        if !base_model?(klass) && config.table_name_nesting && config.suffix_parent
          config.nesting_seperator + parent_name(klass)
        end
      end

      def self.parent_name(klass)
        if config.singular_parent
          klass.superclass.table_name.singularize
        else
          klass.superclass.table_name
        end
      end

      # def self.namespaces(klass_name)
      #   return [] if klass_name.nil?
      #   # klass_name = klass.name
      #   seperator = config.nesting_seperator
      #   list = klass_name.split('::')
      #   list.each_index.collect do |i|
      #     list.slice(i, list.length - i).join(seperator).underscore.downcase
      #   end
      # end
    end
  end
end
