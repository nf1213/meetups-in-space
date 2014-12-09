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

def authenticate!
  unless signed_in?
    flash[:notice] = 'You need to sign in if you want to do that!'
    redirect '/'
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

get '/example_protected_page' do
  authenticate!
end

get '/create' do
  @planets = Planet.all

  erb :create
end

post '/create' do
  name = params[:name]
  desc = params[:description]
  planet = params[:planet]
  loc = params[:location]
  creator = current_user.id
  can_create = name != '' && desc != '' && loc != '' && signed_in?

  if can_create
    mu = Meetup.create!(name: name, description: desc, location: loc, planet_id: planet, creator_id: creator)
    redirect "/meetups/#{mu.id}"
  else
    redirect "/create"
  end
end

get '/meetups/:id' do
  @meetup = Meetup.find(params[:id])
  @creator = User.find(@meetup.creator_id).username
  @comments = @meetup.comments.order(created_at: :desc)
  @signed_in = signed_in?
  if @signed_in
    @joined = current_user.meetups.exists?(id: @meetup)
  end

  erb :show
end

post '/comment/:id' do
  meetup = params[:id]
  can_create = signed_in? && text != '' && current_user.meetups.exists?(id: meetup)

  if can_create
    text = params[:comment]
    user = current_user.id
    Comment.create!(content: text, user_id: user, meetup_id: meetup)
  end
  redirect "/meetups/#{meetup}"
end

get '/join/:id' do
  meetup = params[:id]
  user = current_user.id
  joined = current_user.meetups.exists?(id: meetup)
  if joined
    reservation = Reservation.find_by(user_id: user, meetup_id: meetup).id
    Reservation.destroy(reservation)
  else
    Reservation.create!(meetup_id: meetup, user_id: user)
  end
  redirect "/meetups/#{meetup}"
end
