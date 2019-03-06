module ActiveRecord
  module MTI
    module Table

      def self.find(klass, table_name, parent_class=klass.superclass)
        # puts "Looking up MTI table for #{klass} with #{table_name}"
        if concrete?(parent_class) && parent_mti_table = parent_class.mti_table
          ::ActiveRecord::MTI.child_tables.find(inhparent: parent_mti_table.oid, name: table_name) #|| parent_mti_table
        else
          ::ActiveRecord::MTI.parent_tables.find(name: table_name)
        end
      end

      def self.check(parentclass, table_name)
        find(parentclass, table_name) != nil
      end

      def self.concrete?(klass)
        klass < ::ActiveRecord::Base && !klass.try(:abstract_class?)
      end

      private

      def self.quantify_table_name(klass, table_name)
        klass.pluralize_table_names ? table_name&.pluralize : table_name
      end

      def self.parent_affixed(klass, table_name)
        return table_name unless !base_model?(klass) && config.table_name_nesting
        case config.affix_parent
        when :prefix
          parent_name(klass) + config.nesting_seperator + table_name
        when :suffix
          table_name + config.nesting_seperator + parent_name(klass)
        else
          table_name
        end
      end

      def self.parent_name(klass)
        if config.singular_parent
          klass.superclass.table_name.singularize
        else
          klass.superclass.table_name
        end
      end

      def self.namespaces(klass)
        seperator = config.nesting_seperator
        contained = klass.parent_name.split('::').join(seperator) { |part| part.underscore.downcase.singularize }
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
