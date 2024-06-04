class ApplicationController < ActionController::Base
  include Authenticate

  private

  def ensure_authentication_allowed
    if Feature.disabled?(:password_authentication) && Feature.disabled?(:google_authentication)
      redirect_to root_path, alert: "Password and Google authentication are both disabled."
    end
  end
end
