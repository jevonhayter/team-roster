require 'sinatra'
require 'sinatra/reloader' if development?
require 'tilt/erubis'

# Require sessions in the application.
configure do
  enable :sessions
  set :session_secret, 'secret'
  set :erb, :escape_html => true
end

before do
  session[:teams] ||= []
end

helpers do
  def color_code(index)
    if index.even?
      'active'
    else
      'success'
    end
  end
end

# Validate if input is empty?
def validate_if_empty?(player_name, height, position)
  test_input = [player_name, height, position]

  test_input.each do |data|
    if data.empty?
      session[:error] = 'All fields must be filled out'
      redirect back
    end
  end
end

# Validate integer inputs
def validate_integer_data(weight, jersey)
  test_input = [weight, jersey]

  test_input.each do |data|
    test_data = data.to_i.to_s == data

    unless test_data
      session[:error] = 'You have to enter a whole number
                        for weight and jersey number'
      redirect back
    end
  end
end

# Validates jersey uniqueness
def jersey_unique(team, jersey)
  if
    team[:roster].any? { |player| player[:number] == jersey }

    session[:error] = 'Player jersey number must be unique.'
    redirect back
  end
end

# Home page
get '/' do
  erb :index
end

# Show form to enter team name
get '/team' do
  erb :new_team
end

# Create team name
post '/teams' do
  team = params[:team].strip

  if team.empty?
    session[:error] = 'You have to enter at least 1
                      character for your team name!'
    redirect back
  else
    session[:teams] << { name: team, roster: [] }
    session[:success] = 'Thanks for adding your team'
  end

  redirect '/teams'
end

# Show a list of teams
get '/teams' do
  @teams = session[:teams]
  erb :teams
end

# Show team name page to edit
get '/teams/:team_id/edit' do
  id = params[:team_id].to_i
  @team = session[:teams][id]

  erb :edit_team_name
end

# Edit team name
post '/teams/:team_id' do
  id = params[:team_id].to_i
  team = session[:teams][id]
  new_name = params[:team].strip

  if new_name.empty?
    session[:error] = 'You have to enter at least 1
                      character for your team name!'
    redirect back
  else
    team[:name] = new_name
    session[:warning] = 'You edited your name successfully!'
    redirect :teams
  end
end

# Delete team
post '/teams/:team_id/destroy' do
  id = params[:team_id].to_i
  session[:teams].delete_at(id)

  session[:warning] = 'You deleted your team'
  redirect :teams
end

# Team roster page
get '/rosters/:team_id' do
  id = params[:team_id].to_i
  @team = session[:teams][id]

  erb :roster_page
end

# Show form to enter players
get '/roster/:team_id' do
  @team_id = params[:team_id]
  erb :new_player
end

# Add players to roster
post '/rosters/:team_id' do
  @id = params[:team_id].to_i
  @team = session[:teams][@id]

  # player data
  player_name = params[:name].strip
  height = params[:height].to_s.strip
  weight = params[:weight].strip
  position = params[:position].strip
  number = params[:jersey].strip

  # Validations
  validate_if_empty?(player_name, height, position)
  validate_integer_data(weight, number)
  jersey_unique(@team, number.to_i)

  @team[:roster] << { name: player_name, height: height, weight: weight.to_i,
                      position: position, number: number.to_i }

  session[:success] = 'You added a player to your roster'

  redirect "/rosters/#{@id}"
end

# Show form to edit a player
get '/rosters/:team_id/:player_id' do
  id = params[:player_id].to_i
  @team_id = params[:team_id].to_i
  @team = session[:teams][@team_id]
  @player = @team[:roster][id]

  erb :edit_player
end

# Update roster
post '/rosters/:team_id/:player_id/edit' do
  id = params[:player_id].to_i
  team_id = params[:team_id].to_i
  team = session[:teams][team_id]
  player = team[:roster][id]

  # player data
  player_name = params[:name].strip
  height = params[:height].to_s.strip
  weight = params[:weight].strip
  position = params[:position].strip
  number = params[:jersey].strip

  # Validations
  validate_if_empty?(player_name, height, position)
  validate_integer_data(weight, number)

  # Update player data
  player[:name] = player_name
  player[:height] = height
  player[:weight] = weight
  player[:position] = position
  player[:number] = number

  session[:warning] = 'You updated player information.'
  redirect "/rosters/#{id}"
end

# Delete player from roster
post '/rosters/:team_id/:player_id/destroy' do
  team_id = params[:team_id].to_i
  player_id = params[:player_id].to_i
  team = session[:teams][team_id]

  team[:roster].delete_at(player_id)

  session[:warning] = 'Deleted player'
  redirect "/rosters/#{team_id}"
end
