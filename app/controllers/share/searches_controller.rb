# シェアされた感想を、商品名でさがす。何も入れないときは新しい順に全部出す
class Share::SearchesController < Share::BaseController
  def show
    @query = params[:q].to_s.strip
    @items = Item.shared_for(current_user).by_name(@query)
                 .includes(:user).with_attached_image
                 .order(shared_at: :desc).page(params[:page])
  end
end
