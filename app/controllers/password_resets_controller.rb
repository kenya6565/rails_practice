class PasswordResetsController < ApplicationController
  before_action :get_user,   only: [:edit, :update]
  before_action :valid_user, only: [:edit, :update]
  
  #パスワード再設定が期限切れかどうか
  before_action :check_expiration, only: [:edit, :update]    # （1）への対応

  
  def new
  end
  
  #送られたemailをDBから探してパスワード再設定用リンクを送信
  def create
    @user = User.find_by(email: params[:password_reset][:email].downcase)
    if @user
      @user.create_reset_digest
      @user.send_password_reset_email
      flash[:info] = "Email sent with password reset instructions"
      redirect_to root_url
    else
      flash.now[:danger] = "Email address not found"
      render 'new'
    end
  end
  
  def edit
  end
  
  def update
    #パスワードが空白じゃないか
    if params[:user][:password].empty?                  # （3）への対応
      @user.errors.add(:password, :blank)
      render 'edit'
      #パスワードが正しければ更新する
    elsif @user.update(user_params)                     # （4）への対応
      log_in @user
      flash[:success] = "Password has been reset."
      redirect_to @user
    else
      #無効なパスワードであれば失敗
      render 'edit'                                     # （2）への対応
    end
  end
  
    # パスワード再設定の期限が切れている場合はtrueを返す
    #パスワード再設定メールの送信時間が現在時刻より2時間以上早いのならばOK
  def password_reset_expired?
    reset_sent_at < 2.hours.ago
  end
  
  
  private
  
    def user_params
      params.require(:user).permit(:password, :password_confirmation)
    end

    # パスワード再設定時に最初にユーザーが自分のメールアドレスを入力してそれを撮るときに使う奴
    def get_user
      @user = User.find_by(email: params[:email])
    end

    # 正しいユーザーかどうか確認する
    #上の@userが正しいユーザーかどうか
    # params[:id]は再設定ようのトークン
    def valid_user
      unless (@user && @user.activated? &&
              @user.authenticated?(:reset, params[:id]))
        redirect_to root_url
      end
    end
    
     # トークンが期限切れかどうか確認する
    def check_expiration
      if @user.password_reset_expired?
        flash[:danger] = "Password reset has expired."
        redirect_to new_password_reset_url
      end
    end
end
