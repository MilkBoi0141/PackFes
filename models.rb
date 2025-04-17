require 'bundler/setup'
require 'bcrypt'
Bundler.require

ActiveRecord::Base.establish_connection

class User < ActiveRecord::Base
    has_secure_password
    has_many :posts, dependent: :destroy
    has_many :likes
    has_many :liked_posts, through: :likes, source: :post
    has_many :mylists
    has_many :listed_posts, through: :mylists, source: :post
    has_many :users_tags
    has_many :tags, through: :users_tags
    validates :name, presence: true
    validates :password, presence: true
end

class Post < ActiveRecord::Base
    belongs_to :user
    has_many :items, dependent: :destroy
    has_many :likes
    has_many :liked_users, through: :likes, source: :users
    has_many :mylists
    has_many :listed_users, through: :mylists, source: :users
    has_many :posts_tags
    has_many :tags, through: :posts_tags
end

class Item < ActiveRecord::Base
    belongs_to :post
end

class Like < ActiveRecord::Base
    belongs_to :user
    belongs_to :post
end

class Mylist < ActiveRecord::Base
    belongs_to :user
    belongs_to :post
end

class Tag < ActiveRecord::Base
  has_many :posts_tags
  has_many :posts, through: :posts_tags
  has_many :users_tags
  has_many :users, through: :users_tags
end

class PostsTag < ActiveRecord::Base
  belongs_to :post
  belongs_to :tag
end

class UsersTag < ActiveRecord::Base
  belongs_to :user
  belongs_to :tag
end