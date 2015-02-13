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
      format.html { redirect_to "http://test.dmp.com/sync?#{url}", status: 301 }
    end
  end
end
