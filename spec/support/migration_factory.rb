module MigrationFactory

  def create_valid_up_and_down_migration(name)
    create_migration(name, valid_up_and_down_migration)
  end

  def create_valid_change_migration(name)
    create_migration(name, valid_change_migration)
  end  

  def create_invalid_up_and_down_migration(name)
    create_migration(name, invalid_up_and_down_migration)
  end

  def create_invalid_change_migration(name)
    create_migration(name, invalid_change_migration)
  end    

  private

    def create_migration(name, content)
      migration = File.new("db/migrate/#{name}.rb", 'w')
      migration.write(content)
      migration.close
      migration      
    end

    def valid_up_and_down_migration
      <<-EOS
        class ILikeCheese < ActiveRecord::Migration
          def up
            add_column :my_table, :my_column, :string
          end

          def down
            remove_column :my_table, :my_column
          end
        end
        
      EOS
    end

    def valid_change_migration
      <<-EOS
        class ILikeCheese < ActiveRecord::Migration
          def change
            add_column :my_table, :my_column, :string
          end
        end
        
      EOS
    end    

    def invalid_up_and_down_migration
      <<-EOS
        class ILikeCheese < ActiveRecord::Migration
          def up
          end

          def down
          end
        end
        
      EOS
    end

    def invalid_change_migration
      <<-EOS
        class ILikeCheese < ActiveRecord::Migration
          def change
          end
        end
        
      EOS
    end  

end