class User < ApplicationRecord
  has_many :microposts, dependent: :destroy
  #中間テーブルの定義
  has_many :active_relationships,  class_name:  "Relationship",
                                   foreign_key: "follower_id",
                                   dependent:   :destroy
  has_many :passive_relationships, class_name:  "Relationship",
                                   foreign_key: "followed_id",
                                   dependent:   :destroy
  # followed＿idカラムはfollowing_idカラムと思うとわかりやすい
  has_many :following, through: :active_relationships,  source: :followed
  has_many :followers, through: :passive_relationships, source: :follower
  
  attr_accessor :remember_token, :activation_token, :reset_token
  # DB保存前に実行
  before_save   :downcase_email
  
  # ユーザーの有効化はユーザーインスタンス作成前に行いたいので
  before_create :create_activation_digest
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
  
  # アカウントを有効にする
  def activate
    # update_attribute(:activated,    true)
    # update_attribute(:activated_at, Time.zone.now)
    update_columns(activated: true, activated_at: Time.zone.now)
  end
  
  # 有効化用のメールを送信する
  def send_activation_email
    UserMailer.account_activation(self).deliver_now
  end
  
  # パスワード再設定の属性を設定する
  def create_reset_digest
    self.reset_token = User.new_token
    update_attribute(:reset_digest,  User.digest(reset_token))
    update_attribute(:reset_sent_at, Time.zone.now)
  end
  
   # パスワード再設定のメールを送信する
  def send_password_reset_email
    UserMailer.password_reset(self).deliver_now
  end
  
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
   # トークンがダイジェストと一致したらtrueを返す
  def authenticated?(attribute, token)
    digest = send("#{attribute}_digest")
    return false if digest.nil?
    BCrypt::Password.new(digest).is_password?(token)
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
  
  # フォローしているユーザーのidを取得
  def feed
    following_ids = "SELECT followed_id FROM relationships
                     WHERE follower_id = :user_id"
    Micropost.where("user_id IN (#{following_ids})
                     OR user_id = :user_id", user_id: id)
  end
  
  # ユーザーをフォローする
  def follow(other_user)
    following << other_user
  end

  # ユーザーをフォロー解除する
  def unfollow(other_user)
    active_relationships.find_by(followed_id: other_user.id).destroy
  end

  # 現在のユーザーがフォローしてたらtrueを返す
  def following?(other_user)
    following.include?(other_user)
  end
  
  
  
  private

    # メールアドレスをすべて小文字にする
  def downcase_email
     self.email = email.downcase
  end

    # 有効化トークンとダイジェストを作成および代入する
  def create_activation_digest
    self.activation_token  = User.new_token
    self.activation_digest = User.digest(activation_token)
  end
end
