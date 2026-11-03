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

    assert_select "nav[aria-label='スマートフォンメニュー'] a[href='#{share_mypage_path}']", text: "シェア"
  end
end
