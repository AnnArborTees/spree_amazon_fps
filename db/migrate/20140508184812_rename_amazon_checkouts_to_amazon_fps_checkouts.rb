class RenameAmazonCheckoutsToAmazonFpsCheckouts < ActiveRecord::Migration
  def change
    rename_table :spree_amazon_checkouts, :spree_amazon_fps_checkouts
  end
end
