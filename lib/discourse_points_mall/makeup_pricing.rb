# frozen_string_literal: true

module DiscoursePointsMall
  module MakeupPricing
    DEFAULT_TIERS = [1000, 3000, 5000].freeze

    def self.tiers
      [
        SiteSetting.points_mall_makeup_price_tier_1.to_i,
        SiteSetting.points_mall_makeup_price_tier_2.to_i,
        SiteSetting.points_mall_makeup_price_tier_3.to_i,
      ].each_with_index.map { |value, index| value.positive? ? value : DEFAULT_TIERS[index] }
    end

    def self.first_tier
      tiers.first
    end

    def self.payload
      prices = tiers
      {
        tier_1: prices[0],
        tier_2: prices[1],
        tier_3: prices[2],
        prices: prices,
      }
    end
  end
end
