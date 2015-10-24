class User < ActiveRecord::Base
  # Include default devise modules. Others available are:
  # :confirmable, :lockable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable,
         :timeoutable

  devise  :omniauthable, :omniauth_providers => [:soundcloud, :google_oauth2, :linkedin, :facebook, :twitter]

  def self.from_omniauth auth

    self.find_user auth

  end

  def self.new_with_session(params, session)

    super.tap do |user|
      if data = session["devise.soundcloud_data"] && session["devise.soundcloud_data"]["extra"]["raw_info"]
        user.email = data["email"] if user.email.blank?
      end
    end
  end

  private

  def self.find_user auth

    case auth.provider

      # Every provider use diferent structures from username and some provide email
      when "soundcloud"
        username = auth.extra.raw_info.username
      when "google_oauth2"
        username = auth.extra.raw_info.name
      when "linked_in"
        username = auth.info.nickname
      when "facebook"
        username = auth.extra.raw_info.name
    end

    where( provider: auth.provider, uid: auth.uid).first_or_create do |user|
      user.provider = auth.provider
      user.email    = "#{auth.uid}@app.com" # find a way to skip validation of email cause no one expose email in API
      user.username = username
      user.password = Devise.friendly_token[0,20]
    end

  end

end
