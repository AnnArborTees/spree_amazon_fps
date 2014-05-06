require 'spec_helper'

describe 'As a user', js: true do
  let!(:user) {create(:user)}
  let!(:country) { create(:country, :states_required => true) }
  let!(:state) { create(:state, :country => country) }
  let!(:shipping_method) { create(:shipping_method) }
  let!(:stock_location) { create(:stock_location) }
  let!(:mug) { create(:product, :name => "RoR Mug") }
  let!(:payment_method) { create(:check_payment_method) }
  let!(:zone) { create(:zone) }

  context 'with a valid order' do
    let!(:product) {create(:product, name: "Test Product")}

    let!(:amazon_payment) {create(:amazon_payment,
        preferred_access_key: 'AKIAJRZRFCCMMSLTZSEQ',
        preferred_secret_key: '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'
      )}

    before :each do
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
      2.times do click_button 'Save and Continue' end
      choose 'Amazon'
      find('#amazon_button').click

      within 'form[name=signIn]' do
        fill_in 'email', with: amazon_email
        fill_in 'password', with: amazon_password
        find('#signInSubmit').click
      end
      2.times do first('input.submit').click end
      wait_for_redirect
      expect(page).to have_content 'Your order has been processed successfully'
    end
  end

private
  def add(product_name)
    visit '/' if current_path != '/'
    find('a', text: product_name).click

    object_with to_cart: -> { click_button 'Add To Cart' }
  end
end
