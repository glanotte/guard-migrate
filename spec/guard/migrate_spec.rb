require 'spec_helper'
require 'tempfile'

describe Guard::Migrate do
  let(:options){ {}}
  let(:paths){{}}

  subject{ Guard::Migrate.new(paths, options) }

  before(:all) do
    FileUtils.mkdir_p('db/migrate')
  end

  after(:all) do
    FileUtils.rm_rf('db')
  end

  describe "options" do
    context "bundler" do
      context "with a gemfile found" do
        before{File.stub(:exist?).and_return(true) }
        its(:bundler?){should be_true}
        its(:rake_string){should match(/^bundle exec rake/)}

        context "with bunder set to false" do
          let(:options){ { :bundler => false }}

          its(:bundler?){should be_false}
          its(:rake_string){should match(/^rake/)}
        end
      end
      context "with no gemfile found" do
        before{File.stub(:exist?).and_return(false)}
        its(:bundler?){should_not be_true}
        its(:rake_string){should match(/^rake/)}
      end
    end

    context "cmd" do
      context "without command customization" do
        its(:cmd?){should_not be_true}
      end

      context "with command customization" do
        before{File.stub(:exist?).and_return(false)}
        let(:options){ { :cmd => "custom command rake" } }

        its(:cmd?){should be_true}
        its(:rake_string){should match(/^custom command rake/)}

        context "without presence of 'rake' keyword" do
          let(:options){ { :cmd => "custom command" } }

          it "should raise and error" do
            pending
          end
        end

        context "with Bundler" do
          before{File.stub(:exist?).and_return(true)}

          its(:rake_string){should match(/^bundle exec custom command rake/)}
        end

        context "with custom rake task specified" do
          context "with duplication of db:migrate" do
            let(:options){ { :cmd => "custom command rake db:migrate" } }

            context "rake_string" do
              it "should contains 'db:migrate' once" do
                subject.rake_string.scan("db:migrate").size.should == 1
              end
            end
          end

          context "with duplication of db:test:clone" do
            let(:options){ { :cmd => "custom command rake db:test:clone" } }

            context "rake_string" do
              it "should contains 'db:test:clone' once" do
                subject.rake_string.scan("db:test:clone").size.should == 1
              end
            end
          end
        end
      end
    end

    context "test clone" do
      context "with no options passed" do
        its(:test_clone?){should be_false}
        its(:rake_string){should match(/rake db:migrate/)}
        its(:rake_string){should_not match(/db:test:clone/)}
      end

      context "when passed false" do
        let(:options){ {:test_clone => false} }
        its(:test_clone?){should be_false}
        its(:rake_string){should match(/rake db:migrate/)}
        its(:rake_string){should_not match(/db:test:clone/)}
      end

      context "when passed true" do
        let(:options){ {:test_clone => true} }
        its(:test_clone?){should be_true}
        its(:rake_string){should match(/rake db:migrate/)}
        its(:rake_string){should match(/db:test:clone/)}
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

      context "when seed is set to true and clone is set to true" do
        let(:options){ {:seed => true, :test_clone => true} }
        it "runs the seed option before the clone option" do
          subject.rake_string.should match(/db:seed.*db:test:clone/)
        end
      end
    end

    context "when the seeds file is passed as the paths" do
      let(:paths){ ['db/seeds.rb'] }
      let(:options){ {:seed => true, :test_clone => true} }
      its(:seed_only_string){ should match(/db:seed db:test:clone/) }

      it "runs the rake command with seed only" do
        subject.should_receive(:system).with(subject.seed_only_string)
        subject.run_on_modifications paths
      end

      context "When reset is set to true" do
        let(:options){ {:seed => true, :reset => true} }

        its(:rake_string){ should match(/db:seed/)}
        its(:rake_string){ should match(/db:migrate:reset/)}
      end
    end
  end

  context "run on change should fixup the path to only the version" do
    ##I don't like this test much - consider refactoring
    let(:paths){ [create_valid_up_and_down_migration('1234_i_like_cheese').path] }
    it "should run the rake command" do
      subject.should_receive(:system).with(subject.rake_string('1234'))
      subject.run_on_modifications paths
    end
  end

  context "run on change when set to reset should only run migrations one time" do
    let(:paths){ [create_valid_up_and_down_migration('1234_i_like_cheese').path, create_valid_change_migration('1235_i_like_cheese').path] }
    let(:options){ {:reset => true, :test_clone => true} }
    it "should run the rake command" do
      subject.should_receive(:system).with(subject.rake_string('1234'))
      subject.run_on_modifications paths
    end
  end

  context "valid/invalid migrations" do

    it "should keep valid up/down migrations" do
      migration = create_valid_up_and_down_migration('1234_i_like_cheese')

      subject.should_receive(:system).with(subject.rake_string('1234'))
      subject.run_on_modifications [migration.path]
    end

    it "should keep valid change migrations" do
      migration = create_valid_change_migration('1234_i_like_cheese')

      subject.should_receive(:system).with(subject.rake_string('1234'))
      subject.run_on_modifications [migration.path]
    end

    it "should remove empty up/down migrations" do
      migration = create_invalid_up_and_down_migration('1234_i_like_cheese')

      subject.should_not_receive(:system).with(subject.rake_string('1234'))
      subject.run_on_modifications [migration.path]
    end

    it "should remove empty change migrations" do
      migration = create_invalid_change_migration('1234_i_like_cheese')

      subject.should_not_receive(:system).with(subject.rake_string('1234'))
      subject.run_on_modifications [migration.path]
    end
  end

end
