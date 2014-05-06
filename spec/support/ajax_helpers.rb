module AjaxHelpers
  def wait_for_ajax
    Timeout.timeout(Capybara.default_wait_time) do
      active = page.evaluate_script('jQuery.active')
      until active == 0
        active = page.evaluate_script('jQuery.active')
      end
    end
  end

  def wait_for_redirect
  	original_url = current_path
  	until current_path != original_url
  		sleep(1)
  	end
  end
end