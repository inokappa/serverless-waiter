require 'json'
require_relative 'libs/client.rb'
require_relative 'libs/notification.rb'

def waiting(bucket, key)
  body = {}
  body['bucket'] = bucket
  body['key'] = key
  body['count'] = 1

  begin
    sqs.send_message(queue_url: ENV['QUEUE_URL'],  message_body: body.to_json)
  rescue Aws::SQS::Errors::ServiceError
    notification('[ERROR] ' + $!.message)
    raise
  end

  '[INFO] オブジェクトが削除されるまで待機します.'
end

def run(event:, context:)
  bucket = event['Records'][0]['s3']['bucket']['name']
  key = event['Records'][0]['s3']['object']['key']
  res = waiting(bucket, key)
  notification(res, log = true)
end
