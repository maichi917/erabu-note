require "omniauth-oauth2"
require "json"

module OmniAuth
  module Strategies
    # LINE Login用のOmniAuthストラテジ。
    # omniauth-line gem（5年以上更新なし）への依存をやめ、
    # メンテナンスされているomniauth-oauth2を土台に自前で実装している。
    class Line < OmniAuth::Strategies::OAuth2
      option :name, "line"
      option :scope, "profile openid"

      option :client_options, {
        site: "https://access.line.me",
        authorize_url: "/oauth2/v2.1/authorize",
        token_url: "/oauth2/v2.1/token"
      }

      def callback_phase
        options[:client_options][:site] = "https://api.line.me"
        super
      end

      def callback_url
        options[:callback_url] || (full_host + script_name + callback_path)
      end

      uid { raw_info["userId"] }

      info do
        {
          name: raw_info["displayName"],
          image: raw_info["pictureUrl"],
          description: raw_info["statusMessage"]
        }
      end

      def raw_info
        @raw_info ||= JSON.parse(access_token.get("v2/profile").body)
      rescue Errno::ETIMEDOUT
        raise Timeout::Error
      end
    end
  end
end
