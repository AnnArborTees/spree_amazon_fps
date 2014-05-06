require 'spec_helper'

describe 'As a user', js: true do
  let!(:user) {create(:user)}

  context 'with a valid order' do
    let!(:order) {create(:order_with_line_items)}
    let!(:product) {create(:product, name: "Test Product")}

    it 'I can pay using Amazon FPS' do
      visit '/'
      add('Test Product').to_cart
      click_button 'Checkout'
      within '.inner[data-hook=billing_inner]' do
        fill_in 'First Name', with: 'Test'
        fill_in 'Last Name', with: 'Johnson'
        fill_in 'Street Address', with: '123 test st.'
        fill_in 'City', with: 'testcity'
        select 'Alabama', from: 'order_bill_address_attributes_state_id'
        fill_in 'Zip', with: '48103'
        fill_in 'Phone', with: '734-123-4567'
      end
      click_button 'Save and Continue'
    end
  end

private
  def add(product_name)
    visit '/' if current_path != '/'
    find('a', text: product_name).click

    object_with to_cart: -> { click_button 'Add To Cart' }
  end
end
