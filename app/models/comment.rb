class Comment < ActiveRecord::Base
  belongs_to :user
  belongs_to :meetup

  validates :content,
    presence: true

  validates :user_id,
    presence: true
end
