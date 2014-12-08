class UniqueReservations < ActiveRecord::Migration
  def change
    add_index :reservations, [:user_id, :meetup_id], unique: true
  end
end
