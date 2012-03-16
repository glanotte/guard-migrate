require 'spec_helper'

describe Guard::Migrate do
  let(:options){ {}}
  let(:paths){{}}

  subject{ Guard::Migrate.new(paths, options) }
  
  describe "options" do
    context "bundler" do
      context "with a gemfile found" do
        before{File.stub!(:exist?).and_return(true) }
        its(:bundler?){should be_true}
        its(:rake_string){should match(/^bundle exec rake/)}

      end
      context "with no gemfile found" do
        before{File.stub!(:exist?).and_return(false)}
        its(:bundler?){should_not be_true}
        its(:rake_string){should match(/^rake/)}
      end

    end
    context "test clone" do
      context "with no options passed" do
        its(:test_clone?){should be_true}
        its(:rake_string){should match(/db:test:clone/)}
      end

      context "when passed false" do
        let(:options){ {:test_clone => false} }
        its(:test_clone?){should_not be_true}
        its(:rake_string){should match(/rake db:migrate/)}
        its(:rake_string){should_not match(/db:test:clone/)}
      end
    end

    context "reset" do
      context "with no options passed" do
        its(:reset?){should_not be_true}

        context "with paths" do
          let(:paths){ ['1234'] }
          it "rake string should attempt redo of changed migration" do
            subject.rake_string(paths.first).should match(/rake db:migrate:redo VERSION\=1234/)
          end
        end
      end

      context "when passed true" do
        let(:options){ {:reset => true} }
        its(:reset?){should be_true}
        its(:rake_string){should match(/rake db:migrate:reset/)}
      end
    end

    context "run on start" do
      context "with no options set" do
        its(:run_on_start?){should_not be_true}

        it "should not run on start" do
          subject.should_receive(:migrate).never
          subject.start
        end

        it "should not run migrate on the reload command" do
          subject.should_receive(:migrate).never
          subject.reload
        end

        it "should not run migrate on the run all command" do
          subject.should_receive(:migrate).never
          subject.run_all
        end
      end

      context "when passed true" do
        let(:options){ {:run_on_start => true} }
        its(:run_on_start?){should be_true}

        it "should run migrate on the start" do
          subject.should_receive(:migrate)
          subject.start
        end

        it "should run migrate on the reload command" do
          subject.should_receive(:migrate)
          subject.reload
        end

        it "should run migrate on the run all command" do
          subject.should_receive(:migrate)
          subject.run_all
        end

        context "with reset set to true" do
          let(:options){ {:run_on_start => true, :reset => true} }
          it "should run a migrate reset on start" do
            subject.rake_string.should match(/db:migrate:reset/)
          end
        end

        context "with reset set to false" do
          let(:options){ {:run_on_start => true, :reset => false} }
          it "should run a regular migrate on start" do
            subject.rake_string.should match(/db:migrate/)
            subject.rake_string.should_not match(/db:migrate:reset/)
            subject.rake_string.should_not match(/db:migrate:redo/)
          end
        end
      end
    end

    context 'Rails Environment' do
      context "when no option is passed" do
        its(:rails_env){should be_nil}
      end

      context "when a rails environment is passed" do
        let(:options){ {:rails_env => 'development'}}
        its(:rails_env){ should == 'development'}

        its(:rake_string){ should match(/RAILS_ENV=development/)}
      end
    end

    context "Seed the database" do
      context "when no option is passed" do
        its(:seed){ should be_nil }
      end

      context "when set to true" do
        let(:options){ {:seed => true} }
        its(:seed){ should be_true }
        its(:rake_string){ should match(/db:seed/)}
      end
    end
  end

  context "run on change should fixup the path to only the version" do
    ##I don't like this test much - consider refactoring
    let(:paths){ ['db/migrate/1234_i_like_cheese.rb'] }
    it "should run the rake command" do
      subject.should_receive(:system).with(subject.rake_string('1234'))
      subject.run_on_change paths
    end
  end
end
