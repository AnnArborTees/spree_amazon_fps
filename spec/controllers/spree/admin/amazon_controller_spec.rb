require 'spec_helper'

describe Spree::Admin::AmazonController, controller: true do
  let!(:user) {create(:user, email: 'test@example.com')}

  context 'when current_order is nil' do
    before :each do
      controller.stub current_order: nil
      controller.stub current_spree_user: nil
    end

    context 'fps' do
      it 'raises ActiveRecord::RecordNotFound' do
        expect( -> { post :fps, use_route: :spree } ).
          to raise_error ActiveRecord::RecordNotFound
      end
    end

    context 'complete' do
      it 'raises ActiveRecord::RecordNotFound' do
        expect( -> { get :complete, use_route: :spree } ).
          to raise_error ActiveRecord::RecordNotFound
      end
    end
  end

  context 'when calling fps action with a valid Amazon payment method' do
    let!(:order) {create(:order)}
    let!(:amazon_payment ) {create(:amazon_payment)}

    before :each do
      amazon_payment.stub preferred_access_key: 'AcCeSs0BCA321'
      amazon_payment.stub preferred_secret_key: 'SeCrEt0ABC123'
      amazon_payment.stub order: order
      controller.stub current_order: order
      controller.stub payment_method: amazon_payment

      post :fps, use_route: :spree, params: { payment_method_id: amazon_payment.id }
    end

    it 'assigns @amazon_params with the correct parameters' do
      expect(assigns[:amazon_params]).to_not be_nil
      expect(assigns[:amazon_params][:accessKey]).to eq amazon_payment.preferred_access_key
      expect(assigns[:amazon_params][:amount]).to eq order.total
      expect(assigns[:amazon_params][:signatureMethod]).to eq 'HmacSHA256'
      expect(assigns[:amazon_params][:signatureVersion]).to eq '2'
      expect(assigns[:amazon_params][:returnUrl]).to eq 'http://example.org/amazon/complete'
      expect(assigns[:amazon_params][:abandonUrl]).to eq 'http://example.org/amazon/abort'
      expect(assigns[:amazon_params][:ipnUrl]).to eq 'http://example.org/amazon/ipn'
      expect(assigns[:amazon_params][:processImmediate]).to eq '0'
      expect(assigns[:amazon_params][:immediateReturn]).to eq '1'
    end

    context 'with an order that results in a description of > 100 characters' do
      let!(:order) {create(:order_with_line_items)}

      it 'truncades the description, trailing in "..."' do
        expect(assigns[:amazon_params][:description][-3..-1]).to eq '...'
      end
    end
  end
end
