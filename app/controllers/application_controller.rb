require 'facebook_api'

class ApplicationController < ActionController::Base
  protect_from_forgery

  def login_required
    if cookies[:user_id].blank?
      store_current_url_as_external_return_url
      redirect_to FacebookApi.authorization_code_url(callback_entries_url)
      return false
    end

    return true
  end

  def login_verify
    results = FacebookApi.authenticate_with_redirect_url_params(callback_entries_url, params)
    if results && results[:access_token]
      facebook_data = FacebookApi.me(results[:access_token])
      cookies[:user_id] = facebook_data[:id]
      # Same some result stuff here
      return true
    end
    return false
  end


  def current_user_photo_url
    FacebookApi.user_photo(cookies[:user_id])
  end

  def store_current_url_as_external_return_url
    store_return_destination(request.url)
  end

  def store_return_destination(return_destination)
    cookies[:xref] = return_destination
  end


end
