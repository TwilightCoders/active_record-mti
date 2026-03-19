ActiveRecord::Schema.define do
  enable_extension 'pgcrypto'
  enable_extension 'uuid-ossp'

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
