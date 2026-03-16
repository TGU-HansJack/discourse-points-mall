# frozen_string_literal: true

class AddCategoryToPointsMallProducts < ActiveRecord::Migration[7.0]
  def change
    add_column :points_mall_products, :category, :string
    add_index :points_mall_products, :category
  end
end
