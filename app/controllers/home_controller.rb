class HomeController < ApplicationController
  def index
    @entries = Entry.all
  end


end
