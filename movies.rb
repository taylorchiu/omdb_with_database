require 'sinatra'
require 'sinatra/reloader'
require 'pry'
require 'pg'

# A setup step to get rspec tests running.
configure do
  root = File.expand_path(File.dirname(__FILE__))
  set :views, File.join(root,'views')
end

get '/' do
erb :index
end


get '/results' do
  c = PGconn.new(:host => "localhost", :dbname => dbname)
  @results = c.exec_params("SELECT * FROM movies WHERE title = $1;", [params["title"]])  # the second value must be an array!
  c.close
    erb :show
end

get '/title/:id' do
  c = PGconn.new(:host => "localhost", :dbname => dbname)
  @results = c.exec_params("SELECT * FROM movies WHERE id = $1;", [params[:id]])
  c.close

  c = PGconn.new(:host => "localhost", :dbname => dbname)
  @movies_actors_common_val = c.exec_params("SELECT * FROM movies_actors WHERE movie_id = $1", [params[:id]])
  c.close
  @actor_id = @movies_actors_common_val[0]["actor_id"]

  c = PGconn.new(:host => "localhost", :dbname => dbname)
  @actor = c.exec_params("SELECT * FROM actors WHERE id = $1", [@actor_id])
  c.close

  erb :info
end

get '/movies/new' do
  erb :new
end

post '/movies' do
  c = PGconn.new(:host => "localhost", :dbname => dbname)
  @new_movie = c.exec_params("INSERT INTO movies (title, year, description, rating) VALUES ($1, $2, $3, $4)",
                  [params["title"], params["year"], params["description"], params["rating"]])
  c.close
  redirect '/confirmation'
  erb :new
end

get '/confirmation' do
  erb :confirmation
end


def dbname
  "testdb"
end

def create_movies_table
  connection = PGconn.new(:host => "localhost", :dbname => dbname)
  connection.exec %q{
  CREATE TABLE movies (
    id SERIAL PRIMARY KEY,
    title varchar(255),
    year varchar(255),
    plot text,
    genre varchar(255)
  );
  }
  connection.close
end

def drop_movies_table
  connection = PGconn.new(:host => "localhost", :dbname => dbname)
  connection.exec "DROP TABLE movies;"
  connection.close
end

def seed_movies_table
  movies = [["Glitter", "2001"],
              ["Titanic", "1997"],
              ["Sharknado", "2013"],
              ["Jaws", "1975"]
             ]
 
  c = PGconn.new(:host => "localhost", :dbname => dbname)
  movies.each do |p|
    c.exec_params("INSERT INTO movies (title, year) VALUES ($1, $2);", p)
  end
  c.close
end

