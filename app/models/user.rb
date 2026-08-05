class User < ApplicationRecord
  EMAIL_FORMAT = /\A[^@\s]+@[^@\s]+\.[^@\s]+\z/
  LINE_PLACEHOLDER_EMAIL_DOMAIN = "line.invalid"

  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :trackable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable,
         :omniauthable, omniauth_providers: [ :line ]
  has_many :items, dependent: :destroy
  has_many :usage_logs, dependent: :destroy
  has_many :categories, dependent: :destroy

  # nameは必須（重複は許可）
  validates :name, presence: true, length: { maximum: 255 }
  validates :email, format: { with: EMAIL_FORMAT }

  # LINE登録時に自動生成された仮メールアドレスかどうか
  def placeholder_email?
    email.to_s.end_with?("@#{LINE_PLACEHOLDER_EMAIL_DOMAIN}")
  end
end
