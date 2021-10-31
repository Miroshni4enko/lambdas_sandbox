# Serverless Framework Ruby Sinatra API service backed by DynamoDB on AWS

Inspired and based off of [aws-ruby-sinatra-dynamodb-api](https://github.com/serverless/examples/tree/master/aws-ruby-sinatra-dynamodb-api).

## Anatomy of the template

This template configures a single function, `api`, which is responsible for handling all incoming requests thanks to configured `http` events. To learn more about `http` event configuration options, please refer to [http event docs](https://www.serverless.com/framework/docs/providers/aws/events/apigateway/). As the events are configured in a way to accept all incoming requests, `Sinatra` framework is responsible for routing and handling requests internally. The implementation takes advantage of `serverless-rack`, which allows you to wrap Rack applications such as Sinatra apps. To learn more about `serverless-rack`, please refer to corresponding [GitHub repository](https://github.com/logandk/serverless-rack). The template also relies on `serverless-ruby-layer` plugin for packaging dependencies from the `Gemfile`. For more details about `serverless-ruby-layer` configuration, please refer to corresponding [GitHub repository](https://github.com/navarasu/serverless-ruby-layer).

Additionally, the template also handles provisioning of a DynamoDB database that is used for storing data about tasks. The Sinatra application exposes usual CRUD endpoints

## Usage

### Prerequisites

Ruby install of `2.7.*`

### Deployment

Install dependencies with:

```
npm install
```

and then perform deployment with:

```
serverless deploy
```

After running deploy, you should see output similar to:

```bash
Serverless: Packaging Ruby Rack handler...
Serverless: Backing up current bundle...
Serverless: Packaging gem dependencies...
Serverless: Packaging service...
Serverless: Excluding development dependencies...
Serverless: Restoring backed up bundle...
Serverless: Creating Stack...
Serverless: Checking Stack create progress...
........
Serverless: Stack create finished...
Serverless: Uploading CloudFormation file to S3...
Serverless: Uploading artifacts...
Serverless: Uploading service aws-ruby-sinatra-dynamodb-api.zip file to S3 (2.68 MB)...
Serverless: Validating template...
Serverless: Updating Stack...
Serverless: Checking Stack update progress...
....................................
Serverless: Stack update finished...
Service Information
service: aws-ruby-sinatra-dynamodb-api
stage: dev
region: us-east-1
stack: aws-ruby-sinatra-dynamodb-api-dev
resources: 13
api keys:
  None
endpoints:
  ANY - https://xxxxxxx.execute-api.us-east-1.amazonaws.com/dev/
  ANY - https://xxxxxxx.execute-api.us-east-1.amazonaws.com/dev/{proxy+}
functions:
  api: aws-ruby-sinatra-dynamodb-api-dev-api
layers:
  None

```

_Note_: In current form, after deployment, your API is public and can be invoked by anyone. For production deployments, you might want to configure an authorizer. For details on how to do that, refer to [http event docs](https://www.serverless.com/framework/docs/providers/aws/events/apigateway/).

### Local development

Thanks to capabilities of `serverless-rack`, it is also possible to run your application locally.

```bash
bundle install --path vendor/bundle
serverless rack serve
```

Additionally, you will need to emulate DynamoDB locally, which can be done by using `serverless-dynamodb-local` plugin. In order to do that, execute the following commands:

```bash
serverless plugin install -n serverless-dynamodb-local
serverless dynamodb install
```

It will add the plugin to `devDependencies` in `package.json` file as well as to `plugins` section in `serverless.yml`. Additionally, it will also install DynamoDB locally.

You should also add the following config to `custom` section in `serverless.yml`:

```yml
custom:
  (...)
  dynamodb:
    start:
      migrate: true
    stages:
      - dev
```

We can take advantage of `IS_OFFLINE` environment variable set by `serverless-rack` plugin which will create a local DynamoDB client in `api.rb`:

```ruby
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
```

Now you can start DynamoDB local with the following command:

```bash
serverless dynamodb start
```

At this point, you can run your application locally with the following command:

```bash
serverless rack serve
```

For additional local development capabilities of `serverless-rack` and `serverless-dynamodb-local` plugins, please refer to corresponding GitHub repositories:

- https://github.com/logandk/serverless-rack
- https://github.com/99x/serverless-dynamodb-local
