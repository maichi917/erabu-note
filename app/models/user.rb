class User < ApplicationRecord
  EMAIL_FORMAT = /\A[^@\s]+@[^@\s]+\.[^@\s]+\z/
  LINE_PLACEHOLDER_EMAIL_DOMAIN = "line.invalid"
  GUEST_EMAIL_DOMAIN = "guest.invalid"
  GUEST_SAMPLE_DATA_PATH = Rails.root.join("config/guest_sample_data.yml")
  GUEST_SAMPLE_IMAGE_DIR = Rails.root.join("app/assets/images/samples")

  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :trackable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable,
         :omniauthable, omniauth_providers: [ :line ]
  has_many :items, dependent: :destroy
  has_many :categories, dependent: :destroy

  # スコープ
  scope :guests, -> { where("email LIKE ?", "%@#{GUEST_EMAIL_DOMAIN}") }

  # nameは必須（重複は許可）
  validates :name, presence: true, length: { maximum: 255 }
  validates :email, format: { with: EMAIL_FORMAT }

  # LINE登録時に自動生成された仮メールアドレスかどうか
  def placeholder_email?
    email.to_s.end_with?("@#{LINE_PLACEHOLDER_EMAIL_DOMAIN}")
  end

  # LINEアカウントと連携済みかどうか
  def line_linked?
    line_user_id.present?
  end

  # ゲスト用の一時アカウントを新規作成する（呼び出すたびに新しいアカウントを作る）
  def self.create_guest!
    create!(
      email: "guest-#{SecureRandom.uuid}@#{GUEST_EMAIL_DOMAIN}",
      name: "ゲスト",
      password: Devise.friendly_token[0, 20]
    )
  end

  # ゲスト（一時）アカウントかどうか
  def guest?
    email.to_s.end_with?("@#{GUEST_EMAIL_DOMAIN}")
  end

  # ゲストアカウントに、機能を理解しやすいサンプルデータ（カテゴリ・アイテム）を用意する。
  # データの中身は config/guest_sample_data.yml に書いている
  def seed_guest_sample_data!
    data = YAML.load_file(GUEST_SAMPLE_DATA_PATH)
    categories_by_name = data["categories"].index_with { |name| categories.create!(name: name) }

    data["items"].each do |attributes|
      image = attributes.delete("image")
      category = categories_by_name.fetch(attributes.delete("category"))
      item = items.create!(attributes.merge(category: category))
      next if image.blank?

      item.image.attach(io: GUEST_SAMPLE_IMAGE_DIR.join(image).open, filename: image)
    end
  end
end
