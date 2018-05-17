[![Version      ](https://img.shields.io/gem/v/active_record-mti.svg?maxAge=2592000)](https://rubygems.org/gems/active_record-mti)
[![Build Status ](https://travis-ci.org/TwilightCoders/active_record-mti.svg)](https://travis-ci.org/TwilightCoders/active_record-mti)
[![Code Climate ](https://api.codeclimate.com/v1/badges/27b02e09b5da0a7ed2fc/maintainability)](https://codeclimate.com/github/TwilightCoders/active_record-mti/maintainability)
[![Test Coverage](https://codeclimate.com/github/TwilightCoders/active_record-mti/badges/coverage.svg)](https://codeclimate.com/github/TwilightCoders/active_record-mti/coverage)
[![Dependencies ](https://badges.depfu.com/badges/172a247844f319b45f01f6e941a0e387/count.svg)](https://depfu.com/github/TwilightCoders/active_record-mti)

# ActiveRecord::MTI

ActiveRecord support for PostgreSQL's native inherited tables (multi-table inheritance)

**Supports**
- Ruby: `2.3`, `2.4`, `2.5`
- ActiveRecord: `4.2`, `5.0`, `5.1`

Confirmed production use in `4.2`

## Installation

Add this line to your application's Gemfile:

    gem 'active_record-mti'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install active_record-mti

## Usage

```ruby
class Account < ::ActiveRecord::Base
  # table_name is 'accounts'
  # ...
end

class User < Account
  # table_name is 'account/users'
  # ...
end

class Developer < Account
  # table_name is 'account/developers'
  # ...
end

class Admin < User
  self.table_name = 'admins'
  # ...
end

class Hacker < Developer
  # table_name is 'account/developer/hackers'
  # ...
end
```

In most cases, you shouldn't have to do anything beyond installing the gem. `ActiveRecord::MTI` will do it's best to determine the nature of inheritance in your models. If your models map to their own tables, `ActiveRecord::MTI` will step in and make sure inheritance is treated appropriately. Otherwise it will gracefully acquiesce to `ActiveRecord`'s built-in `STI`. _(see Table Names section below)_.

### Queries

`ActiveRecord` queries work as usual with the following differences:

- The default query of "\*" is changed to include the OID of each row for subclass discrimination. The default select will be `SELECT "accounts"."tableoid" AS tableoid, "accounts".*` (for example)

### Table Names

Conventionally—to indicate the nature of inheritance—`ActiveRecord::MTI` expects the `table_name` of a child model to follow the `singular_parent_table_name/plural_child_table_name` pattern. As always, if you need to deviate from this, you can explicitly set the `table_name` as shown below, or configure `ActiveRecord::MTI` using the configure block.

Note, `ActiveRecord::MTI` will fall back on the unnested `table_name` if it's unable to find the nested form, and short of that, it will use the superclass's `table_name`.

### Configuration
`ActiveRecord::MTI` can be configured using a configure block.

```ruby
# config/initializers/active_record_mti.rb

ActiveRecord::MTI.configure do |config|
  config.table_name_nesting = true
  config.nesting_seperator = '/'
  config.singular_parent = true
end
```

### Migrations

In your migrations define a table to inherit from another table:

```ruby
class CreateAccounts < ActiveRecord::Migration
  def change
    create_table :accounts do |t|
      t.jsonb      :settings
      t.timestamps null: false
    end

    create_table :users, inherits: :accounts do |t|
      t.string     :firstname
      t.string     :lastname
    end

    create_table :developers, inherits: :users do |t|
      t.string     :url
      t.string     :api_key
    end
  end
end

```

### Schema

A schema will be created that reflects the inheritance chain so that `rake:db:schema:load` will work

```ruby
ActiveRecord::Schema.define(version: 20160910024954) do

  create_table "accounts", force: :cascade do |t|
    t.jsonb    "settings"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
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

## Contributing

1. Fork it ( https://github.com/TwilightCoders/active_record-mti/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
