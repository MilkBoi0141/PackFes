require "logger"
require "bundler/setup"
Bundler.require
require "sinatra/reloader" if development?
require "./models.rb"

enable :sessions

use Rack::Session::Cookie, expire_after: 300

helpers do
    def logged_in?
        session[:user_id]
    end
end

before do
    @isAuthed = logged_in?
end

get '/' do
  @posts = Post.order(created_at: :desc)
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
            PostsTag.create(post_id: post.id.to_i, tag_id: tag_id.to_i)
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
