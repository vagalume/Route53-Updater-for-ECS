# Route53-Updater-for-ECS

You may have ECS task definitions that need to register an IP change. This image helps you to update a Route53 record with host's public IPv4 address. This way you don't have to use Elastic Load Balancer (ELB) with a single entry and still have redundancy in case of host failure through Auto Scaling.

## Usage

```
docker run -d -e AWS_ACCESS_KEY_ID=xxxxxx \
              -e AWS_SECRET_ACCESS_KEY=xxxxxx \
              -e AWS_ROUTE53_ZONEID=xxxxxx \
              -e AWS_ROUTE53_HOST=example.domain.com \
              -e AWS_ROUTE53_TTL=600 \
              -e UPDATE_INTERVAL=1000 \
        vagalume/route53-updater:latest
```

## Environment Variables

Environment variables are self explanatory. All you have to do is setup an IAM user with enough permissions to update/create your Route53 record.

## IAM Permissions

The only permission you need is `ChangeResourceRecordSets` in the specific resource. You can use `hostedzone/*` for all zones if you need or enable the permission only in a few zones.

````json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "Stmt1430773925000",
            "Effect": "Allow",
            "Action": [
                "route53:ChangeResourceRecordSets"
            ],
            "Resource": [
                "arn:aws:route53:::hostedzone/xxxxxxxx"
            ]
        }
    ]
}
````
