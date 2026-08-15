namespace :guest do
  desc "作成から24時間以上経過したゲストの一時アカウントを削除する（1日1回の定期実行を想定）"
  task cleanup: :environment do
    count = User.guests.where("created_at < ?", 24.hours.ago).destroy_all.size
    puts "ゲストの一時アカウント: #{count}件を削除しました"
  end
end
