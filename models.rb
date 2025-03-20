require 'bundler/setup'
require 'bcrypt'
Bundler.require

ActiveRecord::Base.establish_connection

class User < ActiveRecord::Base
    has_secure_password
    has_many :posts, dependent: :destroy
    validates :name, presence: true
    validates :password, presence: true
end

class Post < ActiveRecord::Base
    belongs_to :user
    has_many :items, dependent: :destroy
end

class Item < ActiveRecord::Base
    belongs_to :post
end