class Meetup < ActiveRecord::Base
  has_many :reservations
  has_many :comments
  belongs_to :planet
  has_many :users, through: :reservations
end
