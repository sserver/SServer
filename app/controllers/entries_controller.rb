class EntriesController < ApplicationController

  before_filter :login_required, :only => [:new]

  def create
    entry = Entry.new(params[:entry])
    entry.save
    redirect_to home_index_url
  end

  def new
    @photo_url = current_user_photo_url
  end

  def callback
    if login_verify
      return_url = cookies[:xref]
      cookies.delete(:xref)
      redirect_to return_url
    end
  end

end
