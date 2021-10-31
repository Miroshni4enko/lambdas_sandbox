# frozen_string_literal: true

require 'sinatra'
require 'sinatra/json'
require 'aws-sdk-dynamodb'

client_options = if ENV['IS_OFFLINE']
                   {
                     region: 'localhost',
                     endpoint: 'http://localhost:8000',
                     credentials: Aws::Credentials.new(
                       'DEFAULT_ACCESS_KEY',
                       'DEFAULT_SECRET'
                     )
                   }
                 else
                   {}
                 end
dynamodb_client = Aws::DynamoDB::Client.new(client_options)

get '/tasks/:id' do
  result = dynamodb_client.get_item(
    key: { 'id': params[:id] },
    table_name: ENV['TASKS_TABLE']
  )
  item = result.item
  if item
    json id: item['id'], name: item['name'], description: item['description'], status: item['status']
  else
    json error: "Could not find task with id: #{params[:id]}"
  end
end

get '/tasks' do
  result = dynamodb_client.scan(
    table_name: ENV['TASKS_TABLE']
  )
  items = result.items
  if items
    json items.to_json
  else
    json error: "Could not find tasks"
  end
end

put '/tasks/:id' do
  request_payload = JSON.parse(request.body.read)
  table_item = {
    table_name: ENV['TASKS_TABLE'],
    key: {
      id: request_payload['id'],
    },
    update_expression: "SET #task_name = :name, description = :description, #task_status = :status",
    expression_attribute_values: {
      ':name': request_payload['name'],
      ':description': request_payload['description'],
      ':status': request_payload['status']
    },
    expression_attribute_names: {
      '#task_name': "name",
      '#task_status': "status"
    },
    return_values: 'UPDATED_NEW'
  }
  result = dynamodb_client.update_item(table_item)
  if result
    json result.attributes
  else
    json error: "Could not find task with id: #{params[:id]}"
  end
end

delete '/tasks/:id' do
  result = dynamodb_client.delete_item(
    key: { 'id': params[:id] },
    table_name: ENV['TASKS_TABLE']
  )

  if result
    json item_deleted: true
  else
    json error: "Could not find task with id: #{params[:id]}"
  end
end


post '/tasks' do
  request_payload = JSON.parse(request.body.read)
  id = request_payload['id']
  name = request_payload['name']
  description = request_payload['description']
  status = request_payload['status']

  return json error: "Please provide both 'id' and 'name'" unless id && name

  dynamodb_client.put_item(
    item: {
      'id': id,
      'name': name,
      'description': description,
      'status': status,
    },
    table_name: ENV['TASKS_TABLE']
  )

  json id: id, name: name, description: description, status: status
end
