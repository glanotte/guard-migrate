require 'spec_helper'

describe Guard::Migrate do
  let(:options){ {}}
  subject{ Guard::Migrate.new([], options) }
  
  describe "options" do
    context "test clone" do
      context "with no optios passed" do
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
        its(:reset?){should be_true}
        its(:rake_string){should match(/rake db:migrate:reset/)}
      end

      context "when passed false" do
        let(:options){ {:reset => false} }
        its(:reset?){should_not be_true}
        its(:rake_string){should match(/rake db:migrate/)}
        its(:rake_string){should_not match(/rake db:migrate:reset/)}
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
  end

  context "migrate" do
    it "should run the rake command" do
      subject.should_receive(:system).with(subject.rake_string)
      subject.run_on_change []
    end
  end
end
