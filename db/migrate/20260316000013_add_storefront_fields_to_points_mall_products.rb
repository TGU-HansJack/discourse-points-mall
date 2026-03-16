# frozen_string_literal: true

class AddStorefrontFieldsToPointsMallProducts < ActiveRecord::Migration[7.0]
  def change
    add_column :points_mall_products, :featured, :boolean, default: false, null: false
    add_column :points_mall_products, :badge_text, :string

    add_index :points_mall_products, :featured
  end
end
