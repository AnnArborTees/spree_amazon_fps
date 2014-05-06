require 'spec_helper'

describe 'As a user', js: false do
  let!(:user) {create(:user)}

  context 'with a valid order' do
    let!(:order) {create(:order_with_line_items)}

    it 'I can pay using Amazon FPS' do
      visit '/'
      expect(page).to have_content 'what'
    end
  end
end
