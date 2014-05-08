require 'spec_helper'

feature 'Amazon FPS Payment', js: true do
  let!(:user) {create(:admin_user)}
  let!(:country) { create(:country, :states_required => true) }
  let!(:state) { create(:state, :country => country) }
  let!(:shipping_method) { create(:shipping_method) }
  let!(:stock_location) { create(:stock_location) }
  let!(:mug) { create(:product, :name => "RoR Mug") }
  let!(:payment_method) { create(:check_payment_method) }
  let!(:zone) { create(:zone) }

  let!(:amazon_payment) {create(:amazon_payment,
      preferred_access_key: amazon_access_key,
      preferred_secret_key: amazon_secret_key
    )}

  before :each do
    visit '/admin'
    fill_in 'Email', with: user.email
    fill_in 'Password', with: 'secret'
    click_button 'Login'
  end

  context 'with a valid order' do
    let!(:product) {create(:product, name: "Test Product")}

    before :each do
      visit '/'
      add('Test Product').to_cart
      checkout
    end

    scenario 'I can pay using Amazon FPS' do
      pay_with_amazon { expect(page).to have_content 'Test Product x1' }
      expect(page).to have_content 'Your order has been processed successfully'
    end

    scenario 'I cannot use incorrect credentials' do
      pay_with_amazon(email: 'garbage@example.com', password: 'garbage000') do
          expect(page).to have_content 'There was an error with your E-Mail/Password combination. Please try again.'; false
        end
    end

    scenario 'Amazon FPS transactions are properly listed on my Amazon Payments account' do
      pay_with_amazon
      expect(page).to have_content 'Your order has been processed successfully'

      log_in_to_amazon_payments_account
      first('a', text: 'Details').click
      now = Time.now
      expect_transaction_details(
        {'Amount'         => "-#{product.display_price}",
         'Date Completed' => Regexp.new("#{Date::MONTHNAMES[now.month]} #{now.day}, #{now.year}"),
         'For'            => /Test Product x1.*/,
         'Type'           => "Payment",
         'Status'         => "Success" })
    end

    scenario 'I am redirected properly if I leave the Amazon payment page' do
      pay_with_amazon do
        all('a', text: 'here').last.click; false
      end
      expect(current_path).to eq '/checkout/address'
    end
  end

  context 'with an invalid order' do
    # Prices with certain decimals will always fail in Amazon's sandbox
    let!(:bad_product) {create(:product, name: "Bad Product", price: 19.81)}
    
    before :each do
      visit '/'
      add('Bad Product').to_cart
      checkout
    end

    scenario 'a payment will fail, and the order will not complete' do
      pay_with_amazon { expect(page).to have_content 'Bad Product x1' }
      expect(current_path).to eq '/checkout/payment'
      expect(page).to have_content 'Amazon payment failed. You have not been charged.'
    end
  end

  context 'on the admin page' do
    before :each do
      visit '/'
      add('RoR Mug').to_cart
      checkout
      pay_with_amazon

      visit '/admin'
    end

    scenario 'I can refund a payment made with Amazon FPS' do
      find('tr[data-hook=admin_orders_index_rows] > td:nth-child(2) > a').click
      click_link 'Payments'
      find('tr#payment_1 > td > a').click
      click_link 'Refund'
      click_button 'Refund'
      expect(page).to have_content 'Refund Request Sent!'
      expect(page).to have_content "-#{mug.display_price}"

      log_in_to_amazon_payments_account
      first('a', text: 'Details').click
      expect_transaction_details(
        {'Amount' => mug.display_price,
         'Type'   => 'Refund',
         'Status' => 'Success'
        })
    end
  end

private
  def add(product_name)
    visit '/' if current_path != '/'
    find('a', text: product_name).click

    object_with to_cart: -> { 
        click_button 'Add To Cart'
      }
  end
  def checkout
    visit '/checkout/address'
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
  end
  def pay_with_amazon(options={})
    choose 'Amazon'
    find('#amazon_button').click

    within 'form[name=signIn]' do
      fill_in    'email', with: options[:email] || amazon_email
      fill_in 'password', with: options[:password] || amazon_password
      find('#signInSubmit').click
    end

    if !block_given? || yield
      2.times do first('input.submit').click unless page.has_content? 'Processing Payment' end
      wait_for_redirect
    end
  end

  def log_in_to_amazon_payments_account(options={})
    visit amazon_fps_url
    if first 'a', text: 'Sign Out'
      click_link 'Sign Out'
      click_link 'Sign In'
    end

    within 'form[name=signIn]' do
      fill_in    'email', with: options[:email] || amazon_email
      fill_in 'password', with: options[:password] || amazon_password
      find('#signInSubmit').click
    end

    expect(page).to have_content('You are in Amazon Payments Sandbox')
  end
  def expect_transaction_details(options)
    within 'table.txnDetails > tbody' do
      options.each do |k, v|
        find('tr > th', text: "#{k.to_s}:")
        find('tr > td', text: v)
      end
    end
  end
end
