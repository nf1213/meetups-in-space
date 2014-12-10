require 'sinatra'
require 'sinatra/activerecord'
require 'sinatra/flash'
require 'omniauth-github'

require_relative 'config/application'

Dir['app/**/*.rb'].each { |file| require_relative file }

helpers do
  def current_user
    user_id = session[:user_id]
    @current_user ||= User.find(user_id) if user_id.present?
  end

  def signed_in?
    current_user.present?
  end
end

def set_current_user(user)
  session[:user_id] = user.id
end

def authenticate!(page)
  unless signed_in?
    flash[:notice] = 'You need to sign in if you want to do that!'
    redirect "/#{page}"
  end
end

get '/' do
  @meetups = Meetup.all.order(:name)
  @signed_in = signed_in?
  erb :index
end

get '/auth/github/callback' do
  auth = env['omniauth.auth']

  user = User.find_or_create_from_omniauth(auth)
  set_current_user(user)
  flash[:notice] = "You're now signed in as #{user.username}!"

  redirect '/'
end

get '/sign_out' do
  session[:user_id] = nil
  flash[:notice] = "You have been signed out."

  redirect '/'
end

get '/create' do
  authenticate!("")
  @planets = Planet.all

  erb :create
end

post '/create' do
  authenticate!("create")
  name = params[:name]
  desc = params[:description]
  planet = params[:planet]
  loc = params[:location]
  creator = current_user.id

  mu = Meetup.new(name: name, description: desc, location: loc, planet_id: planet, creator_id: creator)
  if mu.save
    Reservation.create!(user_id: creator, meetup_id: mu.id)
    flash[:notice] = "You have created this meetup!"
    redirect "/meetups/#{mu.id}"
  else
    errors = ""
    mu.errors.full_messages.each do |error|
      errors << error + ". "
    end
    flash[:notice] = errors
    redirect "/create"
  end
end

get '/meetups/:id' do
  @meetup = Meetup.find(params[:id])
  @creator = User.find(@meetup.creator_id)
  @comments = @meetup.comments.order(created_at: :desc)
  if signed_in?
    @joined = current_user.meetups.exists?(id: @meetup)
    @is_creator = true if @meetup.creator_id == current_user.id
  end

  erb :show
end

post '/comment/:id' do
  meetup = params[:id]
  authenticate!("meetups/#{meetup}")
  user = current_user.id
  text = params[:comment]
  joined = current_user.meetups.exists?(id: meetup)

  if joined
    c = Comment.new(content: text, user_id: user, meetup_id: meetup)
    unless c.save
      flash[:notice] = "Can't submit blank comment."
    end
  else
    flash[:notice] = "You must join meetup to comment."
  end
  redirect "/meetups/#{meetup}"
end

get '/join/:id' do
  meetup = params[:id]
  authenticate!("meetups/#{meetup}")
  user = current_user.id
  joined = current_user.meetups.exists?(id: meetup)
  is_creator = true if Meetup.find(meetup).creator_id == current_user.id

  if is_creator
    Meetup.destroy(meetup)
    Reservation.destroy_all(meetup_id: meetup)
    Comment.destroy_all(meetup_id: meetup)
    flash[:notice] = "Meetup cancelled :("
    redirect '/'
  elsif joined
    Reservation.destroy_all(user_id: user, meetup_id: meetup)
    flash[:notice] = "You have left the meetup."
  else
    Reservation.create!(meetup_id: meetup, user_id: user)
    flash[:notice] = "You have joined!"
  end
  redirect "/meetups/#{meetup}"
end
