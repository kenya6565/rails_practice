class MicropostsController < ApplicationController
    before_action :logged_in_user, only: [:create, :destroy]
    before_action :correct_user,   only: :destroy
    
    # 投稿
    def create
        @micropost = current_user.microposts.build(micropost_params)
        @micropost.image.attach(params[:micropost][:image])
        if @micropost.save
          flash[:success] = "Micropost created!"
          redirect_to root_url
        else
          @feed_items = current_user.feed.paginate(page: params[:page])
          render 'static_pages/home'
        end
    end

    def destroy
      
      #このdestroyは上のdestroyと一意ではない、あくまでレコードからmicropostを削除するやつ
      @micropost.destroy
      flash[:success] = "Micropost deleted"
      
      # 一つ前のURLを返します（今回の場合、Homeページになります
      redirect_to request.referrer || root_url
    end
    
    private

    def micropost_params
      params.require(:micropost).permit(:content, :image)
    end
    
    def correct_user
      
      # 現在操作しているユーザーの投稿のidを使用して同一のidをもつ投稿をDBから取得
      @micropost = current_user.microposts.find_by(id: params[:id])
      redirect_to root_url if @micropost.nil?
    end
end
