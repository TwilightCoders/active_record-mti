require 'spec_helper'

# Pins the behaviour the railtie ADDS, which the rest of the suite cannot see.
#
# Rails 7.1+ lazy-loads connection adapters, so PostgreSQLAdapter is not necessarily defined
# when the :active_record load hook fires — verified: in bare ActiveRecord 8.1.2.1 it is not.
# The railtie therefore patches it two ways: immediately if it's already there, and via
# ActiveSupport.on_load(:active_record_postgresqladapter) for when it arrives later.
#
# Every other spec in this suite runs against a booted Combustion app with a postgresql
# database.yml, where the adapter is always loaded early — so the whole suite passes IDENTICALLY
# with the lazy path deleted. That makes this code look removable to anyone tidying up: it is
# insurance rather than a fix for a live defect, and nothing else here would notice its absence.
# This spec is what notices.
describe ActiveRecord::MTI::Railtie do
  let(:mti_adapter_modules) do
    [
      ActiveRecord::MTI::ConnectionAdapters::PostgreSQL::Adapter,
      ActiveRecord::MTI::ConnectionAdapters::PostgreSQL::SchemaStatements
    ]
  end

  describe '.patch_postgresql_adapter!' do
    it 'prepends both adapter modules to whatever class it is handed' do
      klass = Class.new

      described_class.patch_postgresql_adapter!(klass)

      expect(klass.ancestors).to include(*mti_adapter_modules)
    end

    it 'is idempotent — a class patched twice is not patched twice' do
      klass = Class.new

      described_class.patch_postgresql_adapter!(klass)
      before = klass.ancestors.count { |m| mti_adapter_modules.include?(m) }
      described_class.patch_postgresql_adapter!(klass)

      expect(klass.ancestors.count { |m| mti_adapter_modules.include?(m) }).to eq(before)
    end
  end

  describe 'the lazy-load path' do
    # THE REGRESSION THIS FILE EXISTS FOR. Running the load hook is exactly what Rails does when
    # the adapter is required later (activerecord .../postgresql_adapter.rb runs
    # :active_record_postgresqladapter with PostgreSQLAdapter as the context object), so an
    # adapter class that shows up after boot gets patched.
    it 'patches an adapter class that only loads after the :active_record hook has run' do
      late_adapter = Class.new
      expect(late_adapter.ancestors).not_to include(*mti_adapter_modules)

      ActiveSupport.run_load_hooks(:active_record_postgresqladapter, late_adapter)

      expect(late_adapter.ancestors).to include(*mti_adapter_modules),
        'the railtie registered no :active_record_postgresqladapter hook — on a Rails 7.1+ app ' \
        'that has not loaded the adapter yet, MTI would silently never patch it'
    end

    it 'registers that hook rather than relying on the adapter already being loaded' do
      hooks = ActiveSupport.instance_variable_get(:@load_hooks) || {}

      expect(hooks).to have_key(:active_record_postgresqladapter)
    end
  end

  describe 'the eager path' do
    it 'has patched the real adapter in this booted app' do
      # The path taken here and in any app whose database.yml makes Rails load the adapter
      # during boot. Kept alongside the lazy one so a change that fixes only one is visible.
      expect(ActiveRecord::ConnectionAdapters::PostgreSQLAdapter.ancestors).to include(*mti_adapter_modules)
    end

    it 'patches the schema dumper and base regardless of adapter timing' do
      expect(ActiveRecord::SchemaDumper.ancestors).to include(ActiveRecord::MTI::SchemaDumper)
      expect(ActiveRecord::Base.ancestors).to include(ActiveRecord::MTI::CoreExtension)
    end
  end
end
