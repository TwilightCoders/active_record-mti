# ActiveRecord::MTI

ActiveRecord support for PostgreSQL's native inherited tables (multi-table inheritance).

## Requirements

- Ruby **2.7+**
- ActiveRecord **5.2+** (tested through Rails 8.1)
- PostgreSQL **9.4+**

## Installation

Add to your Gemfile:

```ruby
gem 'active_record-mti'
```

## How It Works

PostgreSQL supports table inheritance via `CREATE TABLE child () INHERITS (parent)`.
Child tables inherit all columns from the parent, can add their own, and rows in
child tables appear in queries against the parent. Each row carries a `tableoid`
system column identifying which physical table it belongs to.

`ActiveRecord::MTI` uses `tableoid` to automatically instantiate the correct
Ruby class when querying through a parent table — no discriminator column needed.

## Usage

### Models

```ruby
class Account < ActiveRecord::Base
  # table: accounts
end

class User < Account
  # table: account/users (auto-inferred)
end

class Admin < User
  self.table_name = 'account/admins'
end
```

In most cases, you don't need to do anything beyond installing the gem. MTI will
detect when a model maps to a PostgreSQL inherited table and handle instantiation
automatically.

### Table Name Convention

Child table names follow `singular_parent/plural_child`:

| Model       | Inferred Table Name       |
|-------------|---------------------------|
| `Account`   | `accounts`                |
| `User`      | `account/users`           |
| `Developer` | `account/developers`      |
| `Hacker`    | `account/developer/hackers` |

Override with `self.table_name = '...'` when needed.

### Queries

```ruby
# Queries all child tables via the parent — returns mixed types
Account.all
# => [#<User ...>, #<Admin ...>, #<Developer ...>]

# Queries only the child table
Admin.where(active: true)
# => [#<Admin ...>]

# Associations work transparently
post.commenters  # may return User, Admin, Developer instances
```

The default `SELECT` includes `tableoid` for subclass discrimination:
```sql
SELECT "accounts".*, "accounts"."tableoid" FROM "accounts"
```

### Migrations

```ruby
class CreateAccounts < ActiveRecord::Migration[7.1]
  def change
    create_table :accounts do |t|
      t.jsonb :settings
      t.timestamps
    end

    create_table 'account/users', inherits: :accounts do |t|
      t.string :email
    end

    create_table 'account/admins', inherits: 'account/users' do |t|
      t.integer :access_level
    end
  end
end
```

Child tables automatically inherit the parent's primary key and indexes.

### Schema Dump

`rake db:schema:dump` produces a schema that preserves the inheritance chain:

```ruby
create_table "accounts", force: :cascade do |t|
  t.jsonb "settings"
  t.datetime "created_at", null: false
  t.datetime "updated_at", null: false
end

create_table "account/users", inherits: "accounts" do |t|
  t.string "email"
end
```

### Mixing MTI and STI

A model can use both. The child table can have a `type` column for STI within
the MTI branch:

```ruby
class Vehicle < ActiveRecord::Base
  # table: vehicles (has a `type` column)
end

class Truck < Vehicle
  # table: vehicle/trucks (MTI — own table, inherits from vehicles)
end

class Pickup < Truck
  # STI — shares vehicle/trucks table, discriminated by `type`
end
```

### Known Limitations

- **Child-specific columns** are not available when querying through the parent
  table. `Message.all` returns the correct subclass, but only parent columns are
  populated. Call `.reload` or query the child class directly to access
  child-specific attributes.

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-feature`)
3. Commit your changes
4. Push to the branch
5. Create a Pull Request
