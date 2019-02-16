require 'json'
require 'net/http'
require 'aws-sdk'

def decrypt_slack_url
  kms = Aws::KMS::Client.new
  encrypted_url = Base64.decode64(ENV['SLACK_ENCRYPTED_URL'])
  'https://' + kms.decrypt(ciphertext_blob: encrypted_url).plaintext
end

def notification_params(message)
  params = {
    channel: ENV['SLACK_CHANNEL'],
    username: ENV['SLACK_USERNAME'],
    icon_emoji: ENV['SLACK_ICON_EMOJI'],
    text: message
  }
  params
end

def notification(message, log = nil)
  puts message
  return true if log
  uri = URI.parse(decrypt_slack_url)
  http = Net::HTTP.new(uri.host, uri.port)
  http.use_ssl = true
  http.start do
    request = Net::HTTP::Post.new(uri.path)
    request.set_form_data(payload: notification_params(message).to_json)
    http.request(request)
  end
end
