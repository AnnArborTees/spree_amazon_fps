class AddPaymentMethodToSpreeAmazonCheckouts < ActiveRecord::Migration
  def change
    add_column :spree_amazon_checkouts, :payment_method_id, :integer
  end
end
