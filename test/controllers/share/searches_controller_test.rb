require "test_helper"

class Share::SearchesControllerTest < ActionDispatch::IntegrationTest
  setup do
    User.ensure_sample_users!
    other = users(:two)
    other.items.create!(name: "モイストバランス ローション", rating: 5, review: "本物のユーザーの感想", shared: true)
    other.items.create!(name: "モイストバランス ミルク", rating: 4, review: "シェアしていない感想")
  end

  test "show finds shared reviews by product name for real users" do
    sign_in users(:one)

    get share_search_path, params: { q: "モイスト" }

    assert_response :success
    assert_match "本物のユーザーの感想", response.body
    assert_no_match "シェアしていない感想", response.body
    assert_no_match "冬でもこれ1本", response.body
  end

  test "show lists only sample users' reviews for guests" do
    sign_in User.create_guest!

    get share_search_path, params: { q: "モイスト" }

    assert_match "冬でもこれ1本", response.body
    assert_no_match "本物のユーザーの感想", response.body
  end

  test "show lists all visible shared reviews when the query is blank" do
    sign_in users(:one)

    get share_search_path

    assert_select "article", count: 1
  end
end
