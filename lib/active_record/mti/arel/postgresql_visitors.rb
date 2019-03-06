# module ActiveRecord
#   module MTI
#     module ArelVisitors
#       module PostgreSQL

#         def visit_Arel_Table o, collector
#           collector << " ONLY " if o.only
#           super
#         end

#       end
#     end
#   end
# end
