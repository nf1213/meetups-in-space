class Meetup < ActiveRecord::Base
  has_many :reservations
  has_many :comments
  belongs_to :planet
  has_many :users, through: :reservations

  #validates :something
    #presence: true
    #inclusion: {withing: %W(this, orthis)}
    #length: {is: 5}

  validates :name,
    presence: true

  validates :description,
    presence: true

  validates :location,
    presence: true
end
