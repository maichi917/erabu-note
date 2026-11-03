class User < ApplicationRecord
  EMAIL_FORMAT = /\A[^@\s]+@[^@\s]+\.[^@\s]+\z/
  LINE_PLACEHOLDER_EMAIL_DOMAIN = "line.invalid"
  GUEST_EMAIL_DOMAIN = "guest.invalid"
  SAMPLE_EMAIL_DOMAIN = "sample.invalid"
  SAMPLE_USERS_PATH = Rails.root.join("config/sample_users.yml")
  GUEST_SAMPLE_DATA_PATH = Rails.root.join("config/guest_sample_data.yml")
  GUEST_SAMPLE_IMAGE_DIR = Rails.root.join("app/assets/images/samples")

  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :trackable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable,
         :omniauthable, omniauth_providers: [ :line ]
  has_many :items, dependent: :destroy
  has_many :categories, dependent: :destroy

  # フォロー（users どうしを、中間テーブル follows でつなぐ）
  has_many :active_follows, class_name: "Follow", foreign_key: :follower_id, dependent: :destroy
  has_many :following, through: :active_follows, source: :followed
  has_many :passive_follows, class_name: "Follow", foreign_key: :followed_id, dependent: :destroy
  has_many :followers, through: :passive_follows, source: :follower

  # スコープ
  scope :guests, -> { where("email LIKE ?", "%@#{GUEST_EMAIL_DOMAIN}") }
  # シェアの見本ユーザー（ゲストに見せる）
  scope :samples, -> { where("email LIKE ?", "%@#{SAMPLE_EMAIL_DOMAIN}") }
  # 本物のユーザー
  scope :real_users, -> { where.not("email LIKE ? OR email LIKE ?", "%@#{GUEST_EMAIL_DOMAIN}", "%@#{SAMPLE_EMAIL_DOMAIN}") }

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

  def follow!(user)
    active_follows.find_or_create_by!(followed: user)
  end

  def unfollow!(user)
    active_follows.find_by(followed: user)&.destroy!
  end

  def following?(user)
    following.include?(user)
  end

  # 他のゲストのフォローはカウントしない。
  def visible_following(user)
    following.merge(User.visible_to(user))
  end

  def visible_followers(user)
    followers.merge(User.visible_to(user))
  end

  # タイムライン：フォローしている人の、シェア中の感想
  def timeline_items
    Item.shared_for(self).where(user: following)
  end

  # シェアを最後に開いたあと、新しい感想があれば赤い点を出す
  def new_shares?
    timeline_items.where("items.shared_at > ?", share_seen_at || Time.zone.at(0)).exists?
  end

  # ゲスト（一時）アカウントかどうか
  def guest?
    email.to_s.end_with?("@#{GUEST_EMAIL_DOMAIN}")
  end

  # user から見える人たち。ゲストなら見本のユーザーと自分、本物のユーザーなら本物のユーザー
  def self.visible_to(user)
    user.guest? ? samples.or(where(id: user.id)) : real_users
  end

  # シェアの見本のユーザーと、そのシェア中の感想を用意する（すでにあれば何もしない）。
  # データの中身は config/sample_users.yml に書いている
  def self.ensure_sample_users!
    YAML.load_file(SAMPLE_USERS_PATH)["users"].each do |data|
      user = find_or_create_by!(email: "sample-#{data["key"]}@#{SAMPLE_EMAIL_DOMAIN}") do |new_user|
        new_user.name = data["name"]
        new_user.password = Devise.friendly_token[0, 20]
      end
      next if user.items.exists?

      data["items"].each do |attributes|
        image = attributes.delete("image")
        item = user.items.create!(attributes.merge(shared: true))
        item.image.attach(io: GUEST_SAMPLE_IMAGE_DIR.join(image).open, filename: image) if image.present?
      end
    end
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
