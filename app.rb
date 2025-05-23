require 'active_record'
require "logger"
require "bundler/setup"
Bundler.require
require "sinatra/reloader" if development?
require "./models.rb"

ActiveRecord::Base.establish_connection(ENV['DATABASE_URL'])

if Tag.count == 0
  tag_names = ["ロック", "ポップ", "アイドル", "EDM", "フェス飯", "雨対策"]
  tag_names.each do |name|
    Tag.find_or_create_by(name: name)
  end
end

enable :sessions
use Rack::Session::Cookie,
  key: 'rack.session',
  path: '/',
  expire_after: 86400,
  secret: ENV['SESSION_SECRET'] || 'fallback_secret',
  same_site: :lax,
  secure: production?

helpers do
    def logged_in?
        session[:user_id]
    end
end

before do
    @isAuthed = logged_in?
end

get '/' do
  if session[:user_id]
    current_user = User.find(session[:user_id])
    user_tag_ids = current_user.tags.pluck(:id)
    user_tag_ids = [0] if user_tag_ids.empty?

    @posts = Post
      .left_joins(:posts_tags)
      .left_joins(:likes)
      .select("posts.*, 
               COUNT(DISTINCT CASE WHEN posts_tags.tag_id IN (#{user_tag_ids.join(',')}) THEN posts_tags.tag_id END) AS tag_match_count, 
               COUNT(DISTINCT likes.id) AS likes_count")
      .group("posts.id")
      .order("tag_match_count DESC, likes_count DESC")
      .includes(:tags, :items, :likes, :mylists)


  else
    @posts = Post
      .left_joins(:likes)
      .group('posts.id')
      .select('posts.*, COUNT(likes.id) AS likes_count')
      .order('likes_count DESC')
      .includes(:tags, :items, :likes, :mylists)
  end

  erb :index
end

get '/signup' do
    erb :signup
end

post '/signup' do
    @user = User.create(
        name: params[:name],
        email: params[:email],
        password: params[:password],
        password_confirmation: params[:password_confirmation]
    )
    
    if @user.persisted?
        tag_ids = params[:tag_ids] || []
        tag_ids.each do |tag_id|
            UsersTag.create(user_id: @user.id, tag_id: tag_id)
        end
        
        session[:user_id] = @user.id
        session[:user_name] = @user.name
        redirect '/'
    else
        redirect '/signup'
    end
end


get '/signin' do
    erb :signin
end

post '/signin' do
    user = User.find_by(email: params[:email])
    if user && user.authenticate(params[:password])
        session[:user_id] = user.id
        session[:user_name] = user.name
        redirect '/'
    else
        redirect '/signin'
    end
end

get '/create_post' do
    @items = session[:items] || []
    erb :create_post
end

post '/add_item' do
    session[:items] ||= []
    session[:items] << {
        "name" => params[:name], 
        "amount" => params[:amount], 
        "detail" => params[:detail]
    }
    redirect '/create_post'
end

post '/delete_item/:index' do
  session[:items]&.delete_at(params[:index].to_i)
  redirect '/create_post'
end

post '/post_content' do
    puts "🎯 tag_ids: #{params[:tag_ids].inspect}"
    if session[:items]
        post = Post.create(
            title: params[:title],
            detail: params[:detail],
            user_id: session[:user_id]
        )
        
        tag_ids = params[:tag_ids] || []
        tag_ids.each do |tag_id|
            PostsTag.create(post_id: post.id, tag_id: tag_id)
        end

        session[:items].each do |item_data|
            post.items.create(
                  name: item_data["name"],
                  amount: item_data["amount"].to_i,
                  detail: item_data["detail"],
                  post_id: post.id
            )
        end
    else 
        redirect '/create_post'
    end
    
    session[:items] = nil
    redirect '/'
end

post '/posts/:id/like' do
    post = Post.find(params[:id])
    if logged_in?
        unless Like.exists?(user_id: session[:user_id], post_id: post.id)
            Like.create(user_id: session[:user_id], post_id: post.id)
        end
    end
    redirect '/'
end

post '/posts/:id/unlike' do
    post = Post.find(params[:id])
        if logged_in?
            like = Like.find_by(user_id: session[:user_id], post_id: post.id)
            like&.destroy
        end
    redirect '/'
end

post '/posts/:id/add_mylist' do
    post = Post.find(params[:id])
    if logged_in?
        unless Mylist.exists?(user_id: session[:user_id], post_id: post.id)
            Mylist.create(user_id: session[:user_id], post_id: post.id)
        end
    end
    redirect '/'
end

post '/posts/:id/remove_mylist' do
    post = Post.find(params[:id])
        if logged_in?
            mylist = Mylist.find_by(user_id: session[:user_id], post_id: post.id)
            mylist&.destroy
        end
    redirect '/'
end

get '/user_page' do
    unless session[:user_id]
        redirect '/signin' 
    else
        @user = User.find(session[:user_id])
        @liked_posts = @user.liked_posts
        @saved_posts = @user.mylists.includes(post: :items).map(&:post)
        @myposts = @user.posts
        erb :user_page
    end
end

get '/search' do
  keyword = params[:q]
  if keyword && !keyword.empty?
    @posts = Post.where("title ILIKE ? OR detail ILIKE ?", "%#{keyword}%", "%#{keyword}%").order(:created_at)
  else
    @posts = []
  end
  erb :search
end

get '/signout' do
    session.clear
    redirect '/'
end
