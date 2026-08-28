require "test_helper"
require "rake"

class GuestCleanupTaskTest < ActiveSupport::TestCase
  setup do
    Rails.application.load_tasks if Rake::Task.tasks.empty?
    Rake::Task["guest:cleanup"].reenable
  end

  test "作成から24時間以上経過したゲストは削除される" do
    old_guest = User.create_guest!
    old_guest.update_column(:created_at, 25.hours.ago)

    Rake::Task["guest:cleanup"].invoke

    assert_not User.exists?(old_guest.id)
  end

  test "作成から24時間経っていないゲストは削除されない" do
    recent_guest = User.create_guest!

    Rake::Task["guest:cleanup"].invoke

    assert User.exists?(recent_guest.id)
  end

  test "ゲストでない通常ユーザーは作成日時に関わらず削除されない" do
    old_user = users(:one)
    old_user.update_column(:created_at, 25.hours.ago)

    Rake::Task["guest:cleanup"].invoke

    assert User.exists?(old_user.id)
  end
end
