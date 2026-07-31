ActiveRecord::Schema.define do
  enable_extension 'pgcrypto'
  # NOT uuid-ossp: nothing in this schema or the specs ever called uuid_generate_v4 — the line
  # was vestigial, and it hard-broke the whole suite the moment the dev box moved to PostgreSQL
  # 18, whose Homebrew build doesn't ship that extension (pg_available_extensions lists pgcrypto
  # and not uuid-ossp). One unused `enable_extension` took the suite from green to "0 examples"
  # for five weeks, which is why an uncommitted railtie fix sat unverifiable in this repo.
  # If a uuid default is ever wanted here, gen_random_uuid() is core Postgres since 13.

  self.verbose = false

  create_table :users, schema: :public, force: true do |t|
    t.string :email, index: :btree
    t.timestamps null: false
  end

  create_table 'user/admins', force: true, inherits: :users do |t|
    t.integer :god_powers
    t.string :type
  end

  create_table 'user/developers', force: true, inherits: :users do |t|
    t.integer :commits
  end

  create_table "user/managers", force: true, inherits: :users do |t|
  end

  create_table 'user/admin/hackers', force: true, inherits: 'user/admins' do |t|
    t.integer :god_powers
  end

  create_table :posts, id: :bigserial, force: true do |t|
    t.integer :user_id
    t.string :title
    t.timestamps null: false
  end

  create_table :post_tags, id: :bigserial, default: nil, primary_key: :post_id, force: true do |t|
    t.string :title
    t.timestamps null: false
  end

  create_table :comments, force: true do |t|
    t.integer :user_id
    t.integer :post_id
    t.timestamps null: false
  end

  #################################
  ### Custom Inheritance Column ###
  #################################

  create_table :vehicles, force: true do |t|
    t.string :color
    t.string :type # Inheritance column
    t.timestamps null: false
  end

  create_table 'vehicle/trucks', force: true, inherits: :vehicles do |t|
    t.integer :bed_size
  end

  ########################################
  ### Hangar Message Hierarchy (MTI)   ###
  ########################################

  create_table :sessions, force: true do |t|
    t.string :name
    t.timestamps null: false
  end

  create_table :messages, force: true do |t|
    t.integer :session_id
    t.integer :sequence
    t.string :type
    t.text :content
    t.timestamps null: false
  end

  add_index :messages, :session_id

  create_table 'message/user_messages', force: true, inherits: :messages do |t|
    t.string :role
  end

  create_table 'message/assistant_responses', force: true, inherits: :messages do |t|
    t.string :model
    t.integer :token_count
  end

  create_table 'message/tool_invocations', force: true, inherits: :messages do |t|
    t.string :tool_name
    t.jsonb :arguments
  end

  create_table 'message/tool_results', force: true, inherits: :messages do |t|
    t.string :tool_name
    t.boolean :success
    t.text :output
  end

  create_table 'message/system_events', force: true, inherits: :messages do |t|
    t.string :event_type
  end
end
