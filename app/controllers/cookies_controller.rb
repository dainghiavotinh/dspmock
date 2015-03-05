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
    data_response = DSPCookieSync::UpdateUsersDataResponse.new
    if data_request.ops.empty?
      data_response.status = DSPCookieSync::ErrorCode::EMPTY_REQUEST
    else
      data_response.status = DSPCookieSync::ErrorCode::NO_ERROR

      data_request.ops.each do |user_data_operation|
        info = DSPCookieSync::NotificationInfo.new
        info.user_id = user_data_operation.user_id
        info.notification_code = DSPCookieSync::NotificationCode::INACTIVE_COOKIE

        data_response.notifications << info
      end
     end
    
    send_data data_response.serialize_to_string
  end
end
