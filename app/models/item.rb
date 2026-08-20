class Item < ApplicationRecord
  attr_accessor :new_category_name, :remove_category

  # 容量の単位の選択肢
  CAPACITY_UNITS = %w[ml g kg 枚 個].freeze

  validates :name, presence: true, length: { maximum: 100 }
  validates :brand_name, length: { maximum: 100 }
  validates :price, numericality: { only_integer: true, allow_blank: true, greater_than_or_equal_to: 0 }
  validates :capacity, numericality: { allow_blank: true, greater_than: 0 }
  validates :capacity_unit, inclusion: { in: CAPACITY_UNITS }, allow_blank: true
  validates :rating, inclusion: { in: 1..5 }, allow_nil: true
  validate :image_content_type
  validate :image_size
  validate :review_requires_rating

  belongs_to :user
  belongs_to :category, optional: true
  has_many :usage_logs, dependent: :destroy
  has_one_attached :image do |attachable|
    attachable.variant :thumbnail, resize_to_fill: [ 160, 160 ], format: :webp, saver: { quality: 80 }
    attachable.variant :preview, resize_to_fill: [ 512, 512 ], format: :webp, saver: { quality: 82 }
  end

  # スコープ
  scope :visible, -> { where(archived: false) }
  scope :archived, -> { where(archived: true) }
  scope :by_name, ->(query) {
    return all if query.blank?

    where("name ILIKE ?", "%#{sanitize_sql_like(query)}%")
  }
  scope :by_category, ->(category_id) {
    return all if category_id.blank?
    return where(category_id: nil) if category_id == "uncategorized"

    where(category_id: category_id)
  }
  scope :by_rating, ->(rating) {
    return all if rating.blank?

    where(rating: rating)
  }

  def current_usage_log
    usage_logs.in_use.order(started_at: :desc).first
  end

  def using?
    current_usage_log.present?
  end

  # 容量あたりのコスト（価格 ÷ 容量）。価格または容量が未入力の場合は nil
  def cost_per_capacity
    return if price.blank? || capacity.blank?

    (price.to_f / capacity).round(1)
  end

  # カテゴリを割り当てる。新規カテゴリ名があれば作成して設定し、
  # 作成に失敗した場合は errors に引き継いで false を返す
  def assign_category(user, category_id:, new_category_name:, remove_category:)
    self.new_category_name = new_category_name.to_s.strip
    self.remove_category = ActiveModel::Type::Boolean.new.cast(remove_category)

    if self.new_category_name.present?
      new_category = user.categories.find_or_initialize_by(name: self.new_category_name)
      unless new_category.save
        new_category.errors[:name].each { |message| errors.add(:new_category_name, message) }
        return false
      end

      self.category = new_category
    elsif self.remove_category
      self.category = nil
    elsif category_id.present?
      self.category = user.categories.find(category_id)
    else
      self.category = nil
    end

    true
  end

  # 手放す。感想が消えないようアーカイブ扱いにし、「なくなりそう」「よく使うもの」は自動でオフに戻す
  def archive!
    update!(archived: true, low_stock_flagged: false, favorite: false)
  end

  # 「手放した」タブから戻す。favoriteには連動させない
  def unarchive!
    update!(archived: false)
  end

  def start_using!(user, started_at, started_at_unknown: false)
    usage_logs.create!(
      user: user,
      started_at: started_at_unknown ? nil : (started_at.presence || Time.current)
    )
  end

  def finish_using!(finished_at, rating: nil, review: nil)
    current_usage_log.update!(
      finished_at: finished_at.presence || Time.current,
      rating: rating.presence,
      review: review.presence
    )
  end

  private

  def review_requires_rating
    return if review.blank? || rating.present?

    errors.add(:base, "レビューを入力する場合、星評価は必須です")
  end

  def image_content_type
    return unless image.attached?
    return if image.content_type.in?(%w[image/jpeg image/png])

    errors.add(:image, "はJPEGまたはPNG形式でアップロードしてください")
  end

  def image_size
    return unless image.attached?
    return if image.byte_size <= 10.megabytes

    errors.add(:image, "は10MB以下にしてください")
  end
end
