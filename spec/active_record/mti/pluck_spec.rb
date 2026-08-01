require 'spec_helper'

# THE TUPLE TRAP.
#
# build_mti projects `tableoid` onto every relation so MTI can discriminate a row's real class.
# `pluck` asks for an explicit column list and returns raw values — it needs no discrimination,
# and faithfully returns whatever the relation projects. Without suppression, every pluck on an
# MTI model silently returns N+1 values per row.
#
# It fails silently and plausibly, which is what makes it expensive rather than annoying:
# `id == x` is simply false, `include?` simply misses, `uniq` simply doesn't dedupe. A consuming
# app measured "0 agreements, 37 disagreements" between two id sets that in truth agreed 33
# times with zero disagreements — nothing raised, and the numbers read as a real architectural
# problem. It bit four separate work streams there in a single day, twice in one hour to someone
# who had already read a warning comment about it. Documentation had been tried and had failed;
# this spec and the suppression it guards are the control.
describe 'pluck on an MTI model' do
  before do
    User.delete_all
    User.create!(email: 'plain@example.com')
    Admin.create!(email: 'admin@example.com', god_powers: 3)
  end

  it 'returns scalars for a single column, not [value, tableoid] pairs' do
    emails = User.pluck(:email)

    expect(emails).to all(be_a(String))
    expect(emails).to match_array(%w[plain@example.com admin@example.com])
  end

  it 'returns exactly N values for N columns' do
    rows = User.pluck(:email, :id)

    expect(rows).to all(have_attributes(size: 2))
  end

  it 'is unaffected by the column TYPE — the trap was never uuid-specific' do
    expect(User.pluck(:id)).to all(be_a(Integer).or(be_a(String)))
    expect(User.pluck(:email)).to all(be_a(String))
  end

  it 'holds under from("ONLY …"), which does not avoid the trap on its own' do
    expect(User.from('ONLY users').pluck(:email)).to all(be_a(String))
  end

  it 'holds for pluck(Arel.sql(...)), which does not avoid it either' do
    expect(User.pluck(Arel.sql('email'))).to all(be_a(String))
  end

  it 'holds on a child table as well as the parent' do
    expect(Admin.pluck(:email)).to eq([ 'admin@example.com' ])
  end

  it 'holds for a grouped pluck — no hidden tableoid group column' do
    rows = User.group(:email).pluck(:email)

    expect(rows).to all(be_a(String))
    expect(rows).to match_array(%w[plain@example.com admin@example.com])
  end

  it 'still lets a caller ask for tableoid explicitly' do
    expect(User.pluck(:email, :tableoid)).to all(have_attributes(size: 2))
  end

  # THE OTHER HALF: suppression is scoped to pluck and must not disturb the mechanism it
  # borrows from. If these fail, the fix went too far.
  describe 'the discrimination mechanism is untouched' do
    it 'still projects tableoid on an ordinary relation' do
      expect(User.all.to_sql).to include('tableoid')
    end

    it 'still discriminates a child row to its real class' do
      expect(User.where(email: 'admin@example.com').first).to be_a(Admin)
    end

    it 'still exposes tableoid on a loaded record' do
      expect(User.first.tableoid).to be_present
    end
  end
end
