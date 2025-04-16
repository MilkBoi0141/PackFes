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