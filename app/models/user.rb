class User < ApplicationRecord
  EMAIL_FORMAT = /\A[^@\s]+@[^@\s]+\.[^@\s]+\z/
  LINE_PLACEHOLDER_EMAIL_DOMAIN = "line.invalid"
  GUEST_EMAIL_DOMAIN = "guest.invalid"

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

  # ゲストアカウントに、機能を理解しやすいサンプルデータ（カテゴリ・アイテム）を用意する
  def seed_guest_sample_data!
    skin_care = categories.create!(name: "スキンケア")
    hair_care = categories.create!(name: "ヘアケア")
    daily_goods = categories.create!(name: "日用品")

    # よく使うもの・なくなりそう（感想はまだ未記入）
    lotion = items.create!(
      name: "モイストバランス ローション", brand_name: "kinari", category: skin_care,
      price: 1200, capacity: 120, capacity_unit: "ml",
      favorite: true, low_stock_flagged: true
    )
    lotion.image.attach(
      io: Rails.root.join("app/assets/images/samples/lotion.png").open,
      filename: "lotion.png"
    )

    # よく使うもの（感想あり、なくなりそうではない）
    items.create!(
      name: "デイクリーム", brand_name: "kinari", category: skin_care,
      price: 2400, capacity: 50, capacity_unit: "g",
      favorite: true, rating: 5, review: "毎日のスキンケアに欠かせないアイテムです"
    )

    # 感想あり（高評価）
    items.create!(
      name: "シルクリペア シャンプー", brand_name: "botanica", category: hair_care,
      price: 1500, capacity: 400, capacity_unit: "ml",
      rating: 4, review: "泡立ちが良く、香りも好みでした"
    )

    # 感想あり（低評価）
    serum = items.create!(
      name: "グロウセラム", brand_name: "clear lab", category: skin_care,
      price: 3000, capacity: 30, capacity_unit: "ml",
      rating: 1, review: "肌に合わなかった。次は買わない。"
    )
    serum.image.attach(
      io: Rails.root.join("app/assets/images/samples/serum.png").open,
      filename: "serum.png"
    )

    # レビュー未記入
    items.create!(
      name: "ランドリーソープ", brand_name: "clean days", category: daily_goods,
      price: 800, capacity: 900, capacity_unit: "g"
    )

    # 手放したもの（感想は残る）
    items.create!(
      name: "リッチモイストトリートメント", brand_name: "botanica", category: hair_care,
      price: 1800, capacity: 200, capacity_unit: "g",
      rating: 2, review: "香りは好きだったけど、仕上がりが重たくて合わなかった",
      archived: true
    )
  end
end
