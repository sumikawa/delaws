What's this?
================

A Tool of deleting AWS resources per region.  It's good for cleanup after the evaluation.

Installation
================

    git clone git@github.com:sumikawa/delaws.git
    cd delaws
    bundle install

How to Use
==============

First, confirm list of resources

    bundle exec ./delaws [region name]

After the confirmation, execute the cleaning them up

    bundle exec ./delaws [region name] --go-ahead

Supported Products
========================

- AutoScaling
- CloudFormation
- CloudFront
- CloudWatch
- DynamoDB
- EC2
- ELB
- Elastic Beanstalk
- RDS
- Redshift
