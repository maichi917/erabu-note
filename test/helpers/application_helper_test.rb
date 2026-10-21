require "test_helper"

class ApplicationHelperTest < ActionView::TestCase
  test "star_rating shows filled and empty stars for a whole number rating" do
    assert_equal %(★★★<span class="text-slate-300">☆☆</span>), star_rating(3)
  end

  test "star_rating rounds a decimal rating before rendering" do
    assert_equal %(★★★★<span class="text-slate-300">☆</span>), star_rating(3.6)
  end

  test "current_nav? marks only the menu for the current page" do
    stub_page("items", "reviews")
    assert current_nav?(:reviews)
    assert_not current_nav?(:items)

    stub_page("items", "show")
    assert current_nav?(:items)

    stub_page("items", "new")
    assert current_nav?(:register)
    assert_not current_nav?(:items)

    stub_page("home", "show")
    assert current_nav?(:home)
  end

  private

  def stub_page(controller, action)
    define_singleton_method(:controller_name) { controller }
    define_singleton_method(:action_name) { action }
  end
end
