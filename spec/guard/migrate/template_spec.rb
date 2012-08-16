require 'spec_helper'
require 'guard/guardfile'
require 'files'

@current_dir = Dir.pwd
GUARDFILE_TEMPLATE = "#{File.dirname(__FILE__)}/../../../Guardfile"
GUARD_MIGRATE_GUARDFILE_TEMPLATE = 
  "#{File.dirname(__FILE__)}/../../../lib/guard/migrate/templates/Guardfile"

include Files
working = nil
files_dir = Files do
  working = dir 'working'
end

describe 'templates' do

  before(:each) do
    FileUtils.cd(working)
  end

  describe 'sample guardfile' do

    specify { File.exists?(GUARDFILE_TEMPLATE).should be_true }

    it 'is a sample Guardfile' do
      expect { Guard::Guardfile.create_guardfile }.to_not raise_error
      guardfile_contents = IO.read('Guardfile')
      guardfile_contents.should include('sample Guardfile')
      guardfile_contents.should_not include('db/migrate')
    end

  end

  describe 'Guard::Migrate guardfile template' do

    specify { File.exists?(GUARD_MIGRATE_GUARDFILE_TEMPLATE).should be_true }

    it 'successfully initializes a Guard::Migrate guard' do
      expect { Guard::Guardfile.initialize_template('migrate') }.to_not raise_error
      guardfile_contents = IO.read('Guardfile')
      guardfile_contents.should include('sample Guardfile')
      guardfile_contents.should include('db/migrate')
    end

  end

end

FileUtils.cd(@current_dir)
