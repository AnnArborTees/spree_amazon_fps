class AddRefundInfoToSpreeAmazonCheckouts < ActiveRecord::Migration
  def change
    add_column :spree_amazon_checkouts, :customer_name, :string
    add_column :spree_amazon_checkouts, :refund_transaction_id, :string
    add_column :spree_amazon_checkouts, :refunded_at, :datetime
  end
end
