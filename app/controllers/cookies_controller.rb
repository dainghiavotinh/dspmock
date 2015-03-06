load "#{Rails.root.to_s}/cookie_sync_model.rb" unless defined? DSPCookieSync

class CookiesController < ApplicationController
  def pixel
    p = {
      sid: params["sid"],
      uid: params["uid"],
      google_gid: SecureRandom.hex(20),
      google_cver: 1
    }

    url = p.map { |k, v|
      k.to_s + (v  == true ? "" : "=" + v.to_s) unless [:host, :path].include?(k)
    }.compact.join("&")
    
    respond_to do |format|
      format.html { redirect_to "#{request.protocol}dev0.pin-pg.com/sync?#{url}", status: 301 }
    end
  end

  def upload
    body = request.body.read
    data_request = DSPCookieSync::UpdateUsersDataRequest.new
    data_request.parse_from_string(body)
    Rails.logger.debug(data_request)
    data_response = DSPCookieSync::UpdateUsersDataResponse.new
    status = DSPCookieSync::ErrorCode::NO_ERROR
    has_success = false
    has_error = false
    if data_request.ops.empty?
      data_response.status = DSPCookieSync::ErrorCode::EMPTY_REQUEST
    else
      data_response.status = DSPCookieSync::ErrorCode::NO_ERROR

      data_request.ops.each do |user_data_operation|

        if valid_cookie?(user_data_operation.user_id)
          info = DSPCookieSync::NotificationInfo.new

          info.user_id = user_data_operation.user_id
          info.notification_code = DSPCookieSync::NotificationCode::INACTIVE_COOKIE

          data_response.notifications << info
          has_success = true
        else
          error = DSPCookieSync::ErrorInfo.new
          error.user_id = user_data_operation.user_id
          error.error_code = DSPCookieSync::ErrorCode::BAD_COOKIE

          data_response.errors << error
          has_error = true
	  Rails.logger.debug("bad cookie")
        end
      end
      if has_success 
        status = has_error ? DSPCookieSync::ErrorCode::PARTIAL_SUCCESS : DSPCookieSync::ErrorCode::NO_ERROR 
      else
        status = DSPCookieSync::ErrorCode::BAD_COOKIE
      end
      data_response.status = status
    end

    send_data data_response.serialize_to_string
  end

  private 
  def valid_cookie? user_id
    !user_id.blank? && user_id.length >= 32
  end
end
