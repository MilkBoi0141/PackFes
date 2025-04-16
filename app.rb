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
    @posts = Post.order(:created_at)
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
    if session[:items]
        post = Post.create(
            title: params[:title],
            detail: params[:detail],
            is_owned: true,
            user_id: session[:user_id]
        )

        session[:items].each do |item_data|
            post.items.create(
                  name: item_data["name"],
                  amount: item_data["amount"].to_i,
                  detail: item_data["detail"],
                  post_id: post.id
            )
        end
        redirect '/'
    else 
        redirect '/create_post'
    end
    
    session[:items] = nil
    redirect '/'
end

get '/:id/detail' do
    
end

post '/post_comment' do
    
end

get '/user_page' do
    erb :user_page
end

post '/add_mylist' do
    
end

get '/search' do
    
end

post '/:id/evaluate' do
    
end

get '/signout' do
    session.clear
    redirect '/'
end