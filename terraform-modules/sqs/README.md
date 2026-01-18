# SQS Queue Module

Terraform module for creating Amazon SQS (Simple Queue Service) queues.

## Features

- Creates SQS queues (standard or FIFO)
- Dead-letter queue (DLQ) support
- Message retention period configuration
- Visibility timeout configuration
- Encryption support
- Queue policies
- Tagging support

## Usage

```hcl
module "sqs_chatbot_queue" {
  source = "./terraform-modules/sqs"
  
  create = true
  name   = "my-chatbot-queue"
  
  mandatory_tags = {
    TEAM        = "DevOps"
    DEPARTMENT  = "Engineering"
    OWNER       = "DevOps Team"
    FUNCTION    = "Messaging"
    PRODUCT     = "AI Chatbot"
    ENVIRONMENT = "production"
  }
  
  region = "us-east-1"
}
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| create | Controls if SQS queue should be created | bool | true | no |
| name | Name of the SQS queue | string | - | yes |
| mandatory_tags | Mandatory tags for all resources | object | - | yes |
| custom_tags | Custom tags for all resources | map(string) | {} | no |
| region | AWS region | string | - | yes |

## Outputs

| Name | Description |
|------|-------------|
| queue_url | URL of the SQS queue |
| queue_arn | ARN of the SQS queue |
| queue_name | Name of the SQS queue |

## Prerequisites

- Queue name must be unique within the AWS account and region
- Queue name must follow SQS naming conventions

## Notes

- Standard queues provide at-least-once delivery
- FIFO queues (name ends with `.fifo`) provide exactly-once processing
- Use dead-letter queues to handle messages that cannot be processed
- Message retention period determines how long messages are kept (default: 4 days, max: 14 days)
- Visibility timeout determines how long a message is hidden after being received
- SQS integrates with EKS applications for asynchronous message processing
- Use queue policies to control access to the queue

## Example: Using SQS in Applications

After creating the queue, applications can send and receive messages:

```python
import boto3

sqs = boto3.client('sqs')
queue_url = 'https://sqs.us-east-1.amazonaws.com/123456789012/my-chatbot-queue'

# Send a message
response = sqs.send_message(
    QueueUrl=queue_url,
    MessageBody='Hello, SQS!'
)

# Receive messages
messages = sqs.receive_message(QueueUrl=queue_url)
```

