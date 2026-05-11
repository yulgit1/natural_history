class User < ApplicationRecord

  # Connects this user object to Blacklights Bookmarks.
  include Blacklight::User
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable,
         :omniauthable, omniauth_providers: [:cas]

  def self.from_omniauth(auth)
    netid = auth.uid
    email = "#{netid}@yale.edu"
    where(email: email).first_or_create do |user|
      user.email = email
      user.password = Devise.friendly_token[0, 20]
    end
  end

  # Method added by Blacklight; Blacklight uses #to_s on your
  # user class to get a user-displayable login/identifier for
  # the account.
  def to_s
    email
  end
end
