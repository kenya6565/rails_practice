class AccountActivationsController < ApplicationController
  # ユーザーを有効化する
  def edit
    user = User.find_by(email: params[:email])
    # 既に有効になっているユーザーを誤って再度有効化しないために必要
    #有効になってはいないけど認可されている
    if user && !user.activated? && user.authenticated?(:activation, params[:id])
      user.activate
      log_in user
      flash[:success] = "Account activated!"
      redirect_to user
    else
      flash[:danger] = "Invalid activation link"
      redirect_to root_url
    end
  end
end
