class CreateComments < ActiveRecord::Migration
  def change
    create_table :comments do |t|
      t.string :title
      t.text :content, null: :false
      t.integer :user_id, null: :false
      t.integer :meetup_id, null: :false
    end
  end
end
