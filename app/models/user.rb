class User < ApplicationRecord
  attr_accessor :remember_token
  before_save { self.email = email.downcase }
  validates :name, presence: true, length: { maximum: 50 }
  VALID_EMAIL_REGEX = /\A[\w+\-.]+@[a-z\d\-.]+\.[a-z]+\z/i
  validates :email, presence: true, length: { maximum: 255 },
                    format: { with: VALID_EMAIL_REGEX },
                    uniqueness: true
  has_secure_password
  # パスワードが空のままでも更新できるようにする
  validates :password, presence: true, length: { minimum: 6 }, allow_nil: true
  # 渡された文字列のハッシュ値を返す
  # ハッシュ化されたパスワードを返す
  # リメンバー機能を使うために使用
  def User.digest(string)
    cost = ActiveModel::SecurePassword.min_cost ? BCrypt::Engine::MIN_COST :
                                                  BCrypt::Engine.cost
    BCrypt::Password.create(string, cost: cost)
  end
  
  # ランダムなトークンを返す
  def User.new_token
    SecureRandom.urlsafe_base64
  end
  
  
  # 渡されたトークンがダイジェストと一致したらtrueを返す
  # この引数のremember_tokenはあくまでローカル変数であってアクセサーと同義ではない
  # ブラウザとDBのcookieが同じか
  #bcryptを使ってcookies[:remember_token]がremember_digestと一致することを確認します。
  #bcryptは復元化できないのであくまでその状態で比較するしかない
  # self.remember_digestと同じ
  # ブラウザ側:cookies[:remember_token]
  # DB側:remember_digestカラムに入っている値
  
  # remember_tokenはあくまでBcryptでハッシュ化される前のもののはずなのに
  # その比較対象がBcryptでハッシュ化されているのはなぜ？
  def authenticated?(remember_token)
    return false if remember_digest.nil?
    BCrypt::Password.new(remember_digest).is_password?(remember_token)
  end
  
  # 永続セッションのためにユーザーをデータベースに記憶する
  # ログインボタンを押したときに発動
  # 1行目でattr_accessorを使って「仮想の」属性をuserに作成している
  # 2行目で作成したremember_tokenをハッシュ化してuserのremember_digest属性に入れている
  def remember
    self.remember_token = User.new_token
    update_attribute(:remember_digest, User.digest(remember_token))
  end
  
  # ユーザーのログイン情報を破棄する
  # ログアウトボタンを押したときに発動
  def forget
    update_attribute(:remember_digest, nil)
  end
end
