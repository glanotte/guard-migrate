require 'guard/compat/test/template'

require 'guard/migrate'

RSpec.describe Guard::Migrate do
  describe 'template' do
    subject { Guard::Compat::Test::Template.new(described_class) }

    it 'works' do
      expect(subject.changed('db/seeds.rb')).to eq(%w(db/seeds.rb))
      expect(subject.changed('db/migrate/12345_add_some_field.rb')).to eq(%w(db/migrate/12345_add_some_field.rb))
    end
  end
end
