require 'spec_helper'

describe 'As a user', js: true do
  let!(:user) {create(:user)}

  context 'with a valid order' do
    let!(:country) { create(:country, :states_required => true) }
    let!(:state) { create(:state, :country => country) }
    let!(:shipping_method) { create(:shipping_method) }
    let!(:stock_location) { create(:stock_location) }
    let!(:mug) { create(:product, :name => "RoR Mug") }
    let!(:payment_method) { create(:check_payment_method) }
    let!(:zone) { create(:zone) }

    let!(:user) {create(:user_with_addreses)}
    let!(:product) {create(:product, name: "Test Product")}
    let!(:amazon_payment) {create(:amazon_payment)}

    before :each do
      amazon_payment.stub preferred_access_key: 'AcCeSs0BCA321'
      amazon_payment.stub preferred_secret_key: 'SeCrEt0ABC123'
      Spree::CheckoutController.any_instance.stub try_spree_current_user: user
      Spree::CheckoutController.any_instance.stub skip_state_validation?: true
    end

    it 'I can pay using Amazon FPS' do
      visit '/'
      add('Test Product').to_cart
      click_button 'Checkout'
      within '.inner[data-hook=billing_inner]' do
        fill_in 'First Name', with: 'Test'
        fill_in 'Last Name', with: 'Johnson'
        fill_in 'Street Address', with: '123 test st.'
        fill_in 'City', with: 'Acmar'
        find('#order_bill_address_attributes_state_id').find(:xpath, 'option[2]').select_option
        fill_in 'Zip', with: '35004'
        fill_in 'Phone', with: '734-123-4567'
      end
      click_button 'Save and Continue'
      click_button 'Save and Continue'
      choose 'Amazon'
      find('#amazon_button').click
    end
  end

private
  def add(product_name)
    visit '/' if current_path != '/'
    find('a', text: product_name).click

    object_with to_cart: -> { click_button 'Add To Cart' }
  end
end
