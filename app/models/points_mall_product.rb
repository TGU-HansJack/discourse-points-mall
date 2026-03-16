# frozen_string_literal: true

class PointsMallProduct < ActiveRecord::Base
  self.table_name = 'points_mall_products'

  MAKEUP_CARD_KEY = "makeup_card"

  has_many :orders, class_name: 'PointsMallOrder', foreign_key: 'product_id'

  validates :name, presence: true
  validates :points_cost, presence: true, numericality: { greater_than: 0 }
  validates :product_type, presence: true, inclusion: { in: %w[virtual physical] }
  validates :product_key, uniqueness: true, allow_nil: true, if: -> { self.class.has_product_key? }

  scope :enabled, -> { where(enabled: true) }
  scope :in_stock, -> { where('stock > 0 OR stock IS NULL') }
  scope :ordered, -> { order(sort_order: :asc, created_at: :desc) }

  def self.has_product_key?
    column_names.include?("product_key")
  end

  def self.has_category?
    column_names.include?("category")
  end

  def self.has_featured?
    column_names.include?("featured")
  end

  def self.has_badge_text?
    column_names.include?("badge_text")
  end

  def self.ensure_makeup_card!
    return unless has_product_key?
    first_tier_price = DiscoursePointsMall::MakeupPricing.first_tier
    existing = where(product_key: MAKEUP_CARD_KEY).first
    if existing
      if existing.points_cost != first_tier_price
        existing.update_column(:points_cost, first_tier_price)
      end
      # Backfill legacy records without forcing admin custom values.
      if has_category? && existing.category.blank?
        existing.update_column(:category, "签到工具")
      end
      if has_badge_text? && existing.badge_text.blank?
        existing.update_column(:badge_text, "补签")
      end
      return
    end

    attrs = {
      product_key: MAKEUP_CARD_KEY,
      name: "补签卡",
      description: "用于补签本月漏签日期，每月最多购买与使用 3 次。未使用补签卡次月自动失效。",
      points_cost: first_tier_price,
      stock: nil,
      product_type: "virtual",
      enabled: true,
      sort_order: -100,
    }
    attrs[:category] = "签到工具" if has_category?
    attrs[:badge_text] = "补签" if has_badge_text?
    attrs[:featured] = false if has_featured?
    create!(attrs)
  rescue StandardError => e
    Rails.logger.warn("[points-mall] ensure_makeup_card! failed: #{e.class} #{e.message}")
  end

  def makeup_card?
    self.class.has_product_key? && product_key == MAKEUP_CARD_KEY
  end

  def available?
    enabled && (stock.nil? || stock > 0)
  end

  def decrease_stock!
    return if stock.nil?
    update!(stock: stock - 1)
  end
end
