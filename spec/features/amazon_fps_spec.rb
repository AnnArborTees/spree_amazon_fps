require 'spec_helper'

describe 'As a user', js: true do
  let!(:user) {create(:user)}

  context 'with a valid order' do
    let!(:order) {create(:order_with_line_items)}

    it 'I can pay using Amazon FPS' do
      visit '/'
      sleep('30')
    end
  end
end
