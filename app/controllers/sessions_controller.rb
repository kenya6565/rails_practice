class SessionsController < ApplicationController

  def new
  end

  def create
    # ログインボタン
    # 1,入力したメールとパスワードがユーザーテーブルのレコードと一致しているか確認
    # 2,合っていたら指定されたユーザーidでログイン
    # 3,リメンバー機能のためにクッキーを使ってログインしたユーザーidと
    # 永続トークンをそれぞれハッシュ化して保存
    # ユーザーページに飛ぶ
    user = User.find_by(email: params[:session][:email].downcase)
    if user&.authenticate(params[:session][:password])
      log_in user
      #フラグを立てて1ならダイジェスト保存
      params[:session][:remember_me] == '1' ? remember(user) : forget(user)
      redirect_to user
    else
      flash.now[:danger] = 'Invalid email/password combination'
      render 'new'
    end
  end

  # ログアウト
  def destroy
    log_out if logged_in?
    redirect_to root_url
  end
end