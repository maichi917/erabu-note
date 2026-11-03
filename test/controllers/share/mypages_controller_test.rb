require "test_helper"

class Share::MypagesControllerTest < ActionDispatch::IntegrationTest
  test "show requires login" do
    get share_mypage_path

    assert_redirected_to new_user_session_path
  end

  test "show displays the share header and tabs" do
    sign_in users(:one)

    get share_mypage_path

    assert_response :success
    assert_select "header span", text: "シェア"
    assert_select "nav[aria-label='スマートフォンメニュー'] a[href='#{share_mypage_path}']", text: "マイページ"
    assert_select "nav[aria-label='スマートフォンメニュー'] a[href='#{home_path}']", text: "ノートへ"
  end

  test "the note area shows a link to the share area" do
    sign_in users(:one)

    get home_path

    assert_select "nav[aria-label='スマートフォンメニュー'] a[href='#{share_search_path}']", text: "シェア"
  end

  test "show lists only the current user's shared reviews" do
    user = users(:one)
    items(:one).update!(rating: 4, review: "しっとりする", shared: true)
    items(:two).update!(rating: 3)
    users(:two).items.create!(name: "他の人の化粧水", rating: 5, shared: true)
    sign_in user

    get share_mypage_path

    assert_select "article", count: 1
    assert_select "article", text: /しっとりする/
  end
end
