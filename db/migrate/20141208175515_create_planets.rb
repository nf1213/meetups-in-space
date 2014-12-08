class CreatePlanets < ActiveRecord::Migration
  def change
    create_table :planets do |t|
      t.string :name
    end

    add_column :meetups, :planet_id, :integer
  end
end
