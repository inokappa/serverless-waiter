require 'aws-sdk'
require 'json'
require_relative 'libs/client.rb'
require_relative 'libs/notification.rb'

def object_exists?(bucket, key)
  s3 = Aws::S3::Resource.new 
  b = s3.bucket(bucket)
  return false if b.object(key).exists?
  true
end

def check_progress(bucket, key, num)
  puts "[INFO] #{num} 回目の待機です."
  count = 0
  loop do 
    puts '[INFO] Lambda 関数内でオブジェクトが削除されるまで待機します.'
    break if object_exists?(bucket, key)
    if count > ENV['WAIT_COUNT'].to_i
      waiting(bucket, key, (num.to_i + 1))
      puts '[INFO] 次の Lambda 関数でオブジェクトが削除されるまで待機します.'
      return true
    end
    count += 1
    sleep 1
  end

  '[INFO] :congratulations: オブジェクトの削除が完了しました.'
end

def waiting(bucket, key, num)
  raise '[ERROR] 待機制限 (10 回) を超えたので, 待機を終了します.' if num > 10 

  body = {}
  body['bucket'] = bucket
  body['key'] = key
  body['count'] = num

  begin
    sqs.send_message(queue_url: ENV['QUEUE_URL'],  message_body: body.to_json)
  rescue Aws::SQS::Errors::ServiceError
    notification('[ERROR] ' + $!.message)
    raise
  end
end


def parse_body(message)
  raise '[ERROR] No `body` key in message.' \
    unless message['Records'][0].key?('body')

  JSON.parse(message['Records'][0]['body'])
end

def parse_message_handle(message)
  raise '[ERROR] No `receiptHandle` key in message.' \
    unless message['Records'][0].key?('receiptHandle')

  message['Records'][0]['receiptHandle']
end

def delete_message(handle)
  begin
    sqs.delete_message(queue_url: ENV['QUEUE_URL'], receipt_handle: handle)
  rescue Aws::SQS::Errors::ServiceError
    notification('[ERROR] ' + $!.message)
    raise
  end

  '[INFO] Deleted queue message.'
end

def run(event:, context:)
  # SQS キューメッセージから Body を取得
  body = parse_body(event)
  bucket = body['bucket']
  key = body['key']
  num = body['count']

  # SQS キューのメッセージを削除
  handle = parse_message_handle(event)
  res = delete_message(handle)
  notification(res, true)

  # オブジェクトの削除が完了したかをチェック
  # * 完了していなかったらメッセージをキューイングして終わり
  # * 完了していたら通知を出して終わり
  res = check_progress(bucket, key, num)
  notification(res, log = true)
end
