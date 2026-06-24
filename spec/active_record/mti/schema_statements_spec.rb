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
end
