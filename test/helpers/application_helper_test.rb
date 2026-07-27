require "test_helper"

class ApplicationHelperTest < ActionView::TestCase
  test "format_date formats a date as year/month/day" do
    assert_equal "2026/5/1", format_date(Date.new(2026, 5, 1))
  end

  test "format_date returns a dash when date is nil" do
    assert_equal "-", format_date(nil)
  end

  test "star_rating shows filled and empty stars for a whole number rating" do
    assert_equal %(★★★<span class="text-slate-300">☆☆</span>), star_rating(3)
  end

  test "star_rating rounds a decimal rating before rendering" do
    assert_equal %(★★★★<span class="text-slate-300">☆</span>), star_rating(3.6)
  end

  test "category_filter_class highlights the selected category" do
    assert_equal(
      "rounded-full bg-emerald-600 px-3 py-1.5 text-sm font-semibold text-white",
      category_filter_class("1", "1")
    )
  end

  test "category_filter_class returns the default style for other categories" do
    assert_equal(
      "rounded-full border border-slate-300 bg-white px-3 py-1.5 text-sm font-medium text-slate-700 transition hover:bg-slate-50",
      category_filter_class("1", "2")
    )
  end
end
