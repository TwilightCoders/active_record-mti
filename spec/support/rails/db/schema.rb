ActiveRecord::Schema.define do
  enable_extension 'pgcrypto'
  # NOT uuid-ossp: nothing in this schema or the specs ever called uuid_generate_v4, and
  # PostgreSQL 18's Homebrew build doesn't ship that extension — so one unused line failed
  # schema load and took the whole suite to "0 examples". Same fix as ba87fb2 on develop,
  # applied here independently rather than cherry-picked: these branches have diverged and
  # the railtie between them differs materially.

  self.verbose = false

  create_table :users, force: true do |t|
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
end
