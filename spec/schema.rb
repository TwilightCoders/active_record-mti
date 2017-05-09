ActiveRecord::Schema.define do
  self.verbose = false

  create_table :users, force: true do |t|
    t.string :email
    t.timestamps null: false
  end

  create_table :admins, force: true, inherits: :users do |t|
    t.integer :god_powers
  end

  create_table :posts, force: true do |t|
    t.integer :user_id
    t.string :title
    t.timestamps null: false
  end

  create_table :comments, force: true do |t|
    t.integer :user_id
    t.integer :post_id
    t.timestamps null: false
  end

end
