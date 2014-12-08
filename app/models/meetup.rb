class Meetup < ActiveRecord::Base
  has_many :reservations
  has_many :comments
  has_many :users, through: :reservations
end
