class AddCreatorToMeetups < ActiveRecord::Migration
  def up
    add_column :meetups, :creator_id, :integer
  end

  def down
    remove_column :meetups, :creator_id
  end
end
