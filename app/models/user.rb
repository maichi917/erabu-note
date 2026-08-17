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
  has_many :usage_logs, dependent: :destroy
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

  # ゲストアカウントに、機能を理解しやすいサンプルデータ（カテゴリ・アイテム・使用履歴）を用意する
  def seed_guest_sample_data!
    skin_care = categories.create!(name: "スキンケア")
    hair_care = categories.create!(name: "ヘアケア")
    daily_goods = categories.create!(name: "日用品")

    # 使用中
    moisturizer = items.create!(
      name: "モイストバランス ローション", brand_name: "kinari", category: skin_care,
      price: 1200, stock_quantity: 1, capacity: 120, capacity_unit: "ml"
    )
    moisturizer.usage_logs.create!(user: self, started_at: 10.days.ago)

    # 使い切り済み（レビューあり）
    shampoo = items.create!(
      name: "シルクリペア シャンプー", brand_name: "botanica", category: hair_care,
      price: 1500, stock_quantity: 0, capacity: 400, capacity_unit: "ml"
    )
    shampoo.usage_logs.create!(
      user: self, started_at: 60.days.ago, finished_at: 10.days.ago,
      finish_reason: "used_up", rating: 4, review: "泡立ちが良く、香りも好みでした"
    )

    # 使用中止
    serum = items.create!(
      name: "グロウセラム", brand_name: "clear lab", category: skin_care,
      price: 3000, stock_quantity: 0, capacity: 30, capacity_unit: "ml"
    )
    serum.usage_logs.create!(
      user: self, started_at: 40.days.ago, finished_at: 20.days.ago,
      finish_reason: "discontinued", discontinued_reason: "肌に合わなかった"
    )

    # 未使用・在庫あり
    items.create!(
      name: "ランドリーソープ", brand_name: "clean days", category: daily_goods,
      price: 800, stock_quantity: 3, capacity: 900, capacity_unit: "g"
    )
  end
end
