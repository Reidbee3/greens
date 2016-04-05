class Api::V1::BaseController < ApplicationController
  protect_from_forgery with: :null_session

  before_action :destroy_session

  rescue_from ActiveRecord::RecordNotFound, with: :not_found

  def destroy_session
    request.session_options[:skip] = true
  end

  def not_found
    return api_error(status: 404, errors: 'Identifier not found')
  end

  def api_error(status: 500, errors: [])
    unless Rails.env.production?
      puts errors.full_messages if errors.respond_to? :full_messages
    end
    head status: status and return if errors.empty?

    render(json: jsonapi_format(errors).to_json, status: status)
  end

  def jsonapi_format(errors)
    return errors if errors.is_a? String
    errors_hash = {}
    errors.messages.each do |attribute, error|
      array_hash = []
      error.each do |e|
        array_hash << {attribute: attribute, message: e}
      end
      errors_hash.merge!({ attribute => array_hash })
    end

    return errors_hash
  end

  def authenticate_request!
    return unauthorized! if !request.headers.key?('HTTP_API_KEY') or !APP_CONFIG.key?('api-key')

    return unauthorized! if request.headers['HTTP_API_KEY'].blank? or APP_CONFIG['api-key'].blank?

    return unauthorized! if request.headers['HTTP_API_KEY'] != APP_CONFIG['api-key']
  end

  def unauthorized!
    api_error(status: 401, errors: "Not authorized")
  end

end