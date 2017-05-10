# ActiveRecord::MTI [![Build Status](https://travis-ci.org/TwilightCoders/active_record-mti.svg?branch=master)](https://travis-ci.org/TwilightCoders/active_record-mti) [![Code Climate](https://codeclimate.com/github/TwilightCoders/active_record-mti/badges/gpa.svg)](https://codeclimate.com/github/TwilightCoders/active_record-mti) [![Test Coverage](https://codeclimate.com/github/TwilightCoders/active_record-mti/badges/coverage.svg)](https://codeclimate.com/github/TwilightCoders/active_record-mti/coverage)

Allows for true native inheritance of tables in PostgreSQL

Currently requires Rails 4.2

## Usage

Add this line to your application's Gemfile:

    gem 'active_record-mti'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install active_record-mti

### Migrations

In your migrations define a table to inherit from another table:

```ruby
class CreateAccounts < ActiveRecord::Migration
  def change
    create_table :accounts do |t|
      t.jsonb       :settings
      t.timestamps
    end

    create_table :users, inherits: :accounts do |t|
      t.string      :firstname
      t.string      :lastname
    end

    create_table :developers, inherits: :users do |t|
      t.string      :url
      t.string      :api_key
    end
  end
end

```

### Schema.rb

A schema will be created that reflects the inheritance chain so that rake:db:schema:load will work

```ruby
ctiveRecord::Schema.define(version: 20160910024954) do

  create_table "accounts", force: :cascade do |t|
    t.jsonb    "settings"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "users", inherits: "accounts" do |t|
    t.string "firstname"
    t.string "lastname"
  end

  create_table "developers", inherits: "users" do |t|
    t.string "url"
    t.string "api_key"
  end

end
```

### In your application code

```ruby
class Account < ::ActiveRecord::Base
  uses_mti

end

class User < Account

end

class Developer < Account

end
```

ActiveRecord queries work as usual with the following differences:

* You need to specify which model represents the base of your multi table inheritance tree.  To do so, insert `uses_mti` in the model definition of the base class.
* The default query of "*" is changed to include the OID of each row for subclass discrimination. The default select will be `SELECT cast("accounts"."tableoid"::regclass AS text), "accounts".*`

## Contributing

1. Fork it ( https://github.com/[my-github-username]/active_record-mti/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
