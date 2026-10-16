require 'spec_helper'

describe ActiveRecord::MTI::ConnectionAdapters::PostgreSQL::SchemaStatements do
  let(:connection) { ActiveRecord::Base.connection }

  describe '#fix_inherits_statement' do
    # fix_inherits_statement only reads td.columns / td.check_constraints and mutates
    # td.options in place. A lightweight stand-in keeps the test independent of
    # TableDefinition's constructor (which changes across AR versions) and lets us assert
    # exactly which DDL form is produced. options is a mutable String so #gsub! works.
    def table_definition(columns:, check_constraints:)
      double('TableDefinition',
        columns: columns,
        check_constraints: check_constraints,
        options: +'INHERITS ("data")'
      )
    end

    context 'when the table body is truly empty (no columns, no constraints)' do
      it 'injects an empty column list: () INHERITS (...)' do
        td = table_definition(columns: [], check_constraints: [])

        connection.send(:fix_inherits_statement, td)

        expect(td.options).to eq('() INHERITS ("data")')
      end
    end

    context 'when the table has only a check constraint (no columns)' do
      it 'does NOT inject () — Rails already emits the (CONSTRAINT ...) group' do
        # Regression: previously produced the invalid double group
        # "(CONSTRAINT ...) () INHERITS (...)" and PG raised a syntax error.
        td = table_definition(columns: [], check_constraints: [double('check_constraint')])

        connection.send(:fix_inherits_statement, td)

        expect(td.options).to eq('INHERITS ("data")')
      end
    end

    context 'when the table has columns' do
      it 'does NOT inject () — Rails already emits the column group' do
        td = table_definition(columns: [double('column')], check_constraints: [])

        connection.send(:fix_inherits_statement, td)

        expect(td.options).to eq('INHERITS ("data")')
      end
    end
  end

  describe '#inherit_indexes' do
    after do
      connection.execute('DROP TABLE IF EXISTS "inh_child", "inh_parent"')
    end

    it 'skips a parent index the child already declares, as a schema load does' do
      connection.create_table :inh_parent do |t|
        t.datetime :deleted_at
      end
      connection.add_index :inh_parent, :deleted_at, name: 'idx_inh_parent_deleted'

      expect {
        connection.create_table :inh_child, inherits: :inh_parent do |t|
          t.index :deleted_at, name: 'idx_inh_child_deleted'
        end
      }.not_to raise_error

      expect(connection.indexes(:inh_child).map(&:name)).to eq(['idx_inh_child_deleted'])
    end

    it 'still copies a parent index the child does not declare' do
      connection.create_table :inh_parent do |t|
        t.datetime :deleted_at
      end
      connection.add_index :inh_parent, :deleted_at, name: 'idx_inh_parent_deleted'

      connection.create_table :inh_child, inherits: :inh_parent

      expect(connection.indexes(:inh_child).map(&:name)).to eq(['idx_inh_child_deleted'])
    end
  end
end
