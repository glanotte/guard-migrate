require 'tempfile'

# TODO: replace with guard/compat
require 'guard'

require 'guard/migrate'
RSpec.describe Guard::Migrate do
  let(:options) { { watchers: paths } }
  let(:paths) { {} }

  subject { Guard::Migrate.new(options) }

  before(:all) do
    FileUtils.mkdir_p('db/migrate')
  end

  after(:all) do
    FileUtils.rm_rf('db')
  end

  describe 'options' do
    context 'bundler' do
      context 'with a gemfile found' do
        before { allow(File).to receive(:exist?).and_return(true) }

        describe '#bundler?' do
          subject { super().bundler? }
          it { is_expected.to be_truthy }
        end

        describe '#rake_string' do
          subject { super().rake_string }
          it { is_expected.to match(/^bundle exec rake/) }
        end

        context 'with bunder set to false' do
          let(:options) { { bundler: false } }

          describe '#bundler?' do
            subject { super().bundler? }
            it { is_expected.to be_falsey }
          end

          describe '#rake_string' do
            subject { super().rake_string }
            it { is_expected.to match(/^rake/) }
          end
        end
      end
      context 'with no gemfile found' do
        before { allow(File).to receive(:exist?).and_return(false) }

        describe '#bundler?' do
          subject { super().bundler? }
          it { is_expected.not_to be_truthy }
        end

        describe '#rake_string' do
          subject { super().rake_string }
          it { is_expected.to match(/^rake/) }
        end
      end
    end

    context 'cmd' do
      context 'without command customization' do
        describe '#cmd?' do
          subject { super().cmd? }
          it { is_expected.not_to be_truthy }
        end
      end

      context 'with command customization' do
        before { allow(File).to receive(:exist?).and_return(false) }
        let(:options) { { cmd: 'custom command rake' } }

        describe '#cmd?' do
          subject { super().cmd? }
          it { is_expected.to be_truthy }
        end

        describe '#rake_string' do
          subject { super().rake_string }
          it { is_expected.to match(/^custom command rake/) }
        end

        context "without presence of 'rake' keyword" do
          let(:options) { { cmd: 'custom command' } }

          it 'should raise and error' do
            pending
            fail 'pending'
          end
        end

        context 'with Bundler' do
          before { allow(File).to receive(:exist?).and_return(true) }

          describe '#rake_string' do
            subject { super().rake_string }
            it { is_expected.to match(/^bundle exec custom command rake/) }
          end
        end

        context 'with custom rake task specified' do
          context 'with duplication of db:migrate' do
            let(:options) { { cmd: 'custom command rake db:migrate' } }

            context 'rake_string' do
              it "should contains 'db:migrate' once" do
                expect(subject.rake_string.scan('db:migrate').size).to eq(1)
              end
            end
          end

          context 'with duplication of db:test:clone' do
            let(:options) { { cmd: 'custom command rake db:test:clone' } }

            context 'rake_string' do
              it "should contains 'db:test:clone' once" do
                expect(subject.rake_string.scan('db:test:clone').size).to eq(1)
              end
            end
          end
        end
      end
    end

    context 'test clone' do
      context 'with no options passed' do
        describe '#test_clone?' do
          subject { super().test_clone? }
          it { is_expected.to be_falsey }
        end

        describe '#rake_string' do
          subject { super().rake_string }
          it { is_expected.to match(/rake db:migrate/) }
        end

        describe '#rake_string' do
          subject { super().rake_string }
          it { is_expected.not_to match(/db:test:clone/) }
        end
      end

      context 'when passed false' do
        let(:options) { { test_clone: false } }

        describe '#test_clone?' do
          subject { super().test_clone? }
          it { is_expected.to be_falsey }
        end

        describe '#rake_string' do
          subject { super().rake_string }
          it { is_expected.to match(/rake db:migrate/) }
        end

        describe '#rake_string' do
          subject { super().rake_string }
          it { is_expected.not_to match(/db:test:clone/) }
        end
      end

      context 'when passed true' do
        let(:options) { { test_clone: true } }

        describe '#test_clone?' do
          subject { super().test_clone? }
          it { is_expected.to be_truthy }
        end

        describe '#rake_string' do
          subject { super().rake_string }
          it { is_expected.to match(/rake db:migrate/) }
        end

        describe '#rake_string' do
          subject { super().rake_string }
          it { is_expected.to match(/db:test:clone/) }
        end
      end
    end

    context 'reset' do
      context 'with no options passed' do
        describe '#reset?' do
          subject { super().reset? }
          it { is_expected.not_to be_truthy }
        end

        context 'with paths' do
          let(:paths) { ['1234'] }
          it 'rake string should attempt redo of changed migration' do
            expect(subject.rake_string(paths.first)).to match(/rake db:migrate:redo VERSION\=1234/)
          end
        end
      end

      context 'when passed true' do
        let(:options) { { reset: true } }

        describe '#reset?' do
          subject { super().reset? }
          it { is_expected.to be_truthy }
        end

        describe '#rake_string' do
          subject { super().rake_string }
          it { is_expected.to match(/rake db:migrate:reset/) }
        end
      end
    end

    context 'run on start' do
      context 'with no options set' do
        describe '#run_on_start?' do
          subject { super().run_on_start? }
          it { is_expected.not_to be_truthy }
        end

        it 'should not run on start' do
          expect(subject).to receive(:migrate).never
          subject.start
        end

        it 'should not run migrate on the reload command' do
          expect(subject).to receive(:migrate).never
          subject.reload
        end

        it 'should not run migrate on the run all command' do
          expect(subject).to receive(:migrate).never
          subject.run_all
        end
      end

      context 'when passed true' do
        let(:options) { { run_on_start: true } }

        describe '#run_on_start?' do
          subject { super().run_on_start? }
          it { is_expected.to be_truthy }
        end

        it 'should run migrate on the start' do
          expect(subject).to receive(:migrate)
          subject.start
        end

        it 'should run migrate on the reload command' do
          expect(subject).to receive(:migrate)
          subject.reload
        end

        it 'should run migrate on the run all command' do
          expect(subject).to receive(:migrate)
          subject.run_all
        end

        context 'with reset set to true' do
          let(:options) { { run_on_start: true, reset: true } }
          it 'should run a migrate reset on start' do
            expect(subject.rake_string).to match(/db:migrate:reset/)
          end
        end

        context 'with reset set to false' do
          let(:options) { { run_on_start: true, reset: false } }
          it 'should run a regular migrate on start' do
            expect(subject.rake_string).to match(/db:migrate/)
            expect(subject.rake_string).not_to match(/db:migrate:reset/)
            expect(subject.rake_string).not_to match(/db:migrate:redo/)
          end
        end
      end
    end

    context 'Rails Environment' do
      context 'when no option is passed' do
        describe '#rails_env' do
          subject { super().rails_env }
          it { is_expected.to be_nil }
        end
      end

      context 'when a rails environment is passed' do
        let(:options) { { rails_env: 'development' } }

        describe '#rails_env' do
          subject { super().rails_env }
          it { is_expected.to eq('development') }
        end

        describe '#rake_string' do
          subject { super().rake_string }
          it { is_expected.to match(/RAILS_ENV=development/) }
        end
      end
    end

    context 'Seed the database' do
      context 'when no option is passed' do
        describe '#seed' do
          subject { super().seed }
          it { is_expected.to be_nil }
        end
      end

      context 'when set to true' do
        let(:options) { { seed: true } }

        describe '#seed' do
          subject { super().seed }
          it { is_expected.to be_truthy }
        end

        describe '#rake_string' do
          subject { super().rake_string }
          it { is_expected.to match(/db:seed/) }
        end
      end

      context 'when seed is set to true and clone is set to true' do
        let(:options) { { seed: true, test_clone: true } }
        it 'runs the seed option before the clone option' do
          expect(subject.rake_string).to match(/db:seed.*db:test:clone/)
        end
      end
    end

    context 'when the seeds file is passed as the paths' do
      let(:paths) { ['db/seeds.rb'] }
      let(:options) { { seed: true, test_clone: true } }

      describe '#seed_only_string' do
        subject { super().seed_only_string }
        it { is_expected.to match(/db:seed db:test:clone/) }
      end

      it 'runs the rake command with seed only' do
        expect(subject).to receive(:system).with(subject.seed_only_string)
        subject.run_on_changes paths
      end

      context 'When reset is set to true' do
        let(:options) { { seed: true, reset: true } }

        describe '#rake_string' do
          subject { super().rake_string }
          it { is_expected.to match(/db:seed/) }
        end

        describe '#rake_string' do
          subject { super().rake_string }
          it { is_expected.to match(/db:migrate:reset/) }
        end
      end
    end
  end

  context 'run on change should fixup the path to only the version' do
    # #I don't like this test much - consider refactoring
    let(:paths) { [create_valid_up_and_down_migration('1234_i_like_cheese').path] }
    it 'should run the rake command' do
      expect(subject).to receive(:system).with(subject.rake_string('1234'))
      subject.run_on_changes paths
    end
  end

  context 'run on change when set to reset should only run migrations one time' do
    let(:paths) { [create_valid_up_and_down_migration('1234_i_like_cheese').path, create_valid_change_migration('1235_i_like_cheese').path] }
    let(:options) { { reset: true, test_clone: true } }
    it 'should run the rake command' do
      expect(subject).to receive(:system).with(subject.rake_string('1234'))
      subject.run_on_changes paths
    end
  end

  context 'valid/invalid migrations' do

    it 'should keep valid up/down migrations' do
      migration = create_valid_up_and_down_migration('1234_i_like_cheese')

      expect(subject).to receive(:system).with(subject.rake_string('1234'))
      subject.run_on_changes [migration.path]
    end

    it 'should keep valid change migrations' do
      migration = create_valid_change_migration('1234_i_like_cheese')

      expect(subject).to receive(:system).with(subject.rake_string('1234'))
      subject.run_on_changes [migration.path]
    end

    it 'should remove empty up/down migrations' do
      migration = create_invalid_up_and_down_migration('1234_i_like_cheese')

      expect(subject).not_to receive(:system).with(subject.rake_string('1234'))
      subject.run_on_changes [migration.path]
    end

    it 'should remove empty change migrations' do
      migration = create_invalid_change_migration('1234_i_like_cheese')

      expect(subject).not_to receive(:system).with(subject.rake_string('1234'))
      subject.run_on_changes [migration.path]
    end
  end

end
