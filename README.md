# Preface

We're really happy that you're considering to join us! Here's a challenge that will help us understand your skills and serve as a starting discussion point for the interview.

We're not expecting that everything will be done perfectly as we value your time. You're encouraged to point out possible improvements during the interview though!

Have fun!

## The challenge

Pleo runs most of its infrastructure in Kubernetes. It's a bunch of microservices talking to each other and performing various tasks like verifying card transactions, moving money around, paying invoices ...

We would like to see that you both:
- Know how to create a small microservice
- Know how to wire it together with other services running in Kubernetes

We're providing you with a small service (Antaeus) written in Kotlin that's used to charge a monthly subscription to our customers. The trick is, this service needs to call an external payment provider to make a charge and this is where you come in.

You're expected to create a small payment microservice that Antaeus can call to pay the invoices. You can use the language of your choice. Your service should randomly succeed/fail to pay the invoice.

On top of that, we would like to see Kubernetes scripts for deploying both Antaeus and your service into the cluster. This is how we will test that the solution works.

## Instructions

Start by forking this repository. :)

1. Build and test Antaeus to make sure you know how the API works. We're providing a `docker-compose.yml` file that should help you run the app locally.
2. Create your own service that Antaeus will use to pay the invoices. Use the `PAYMENT_PROVIDER_ENDPOINT` env variable to point Antaeus to your service.
3. Your service will be called if you invoke `/rest/v1/invoices/pay` call on Antaeus. You can probably figure out which call returns the current status invoices by looking at the code ;)
4. Kubernetes: Provide deployment scripts for both Antaeus and your service. Don't forget about Service resources so we can call Antaeus from outside the cluster and check the results.
    - Bonus points if your scripts use liveness/readiness probes.
5. **Discussion bonus points:** Use the README file to discuss how this setup could be improved for production environments. We're especially interested in:
    1. How would a new deployment look like for these services? What kind of tools would you use?
    2. If a developers needs to push updates to just one of the services, how can we grant that permission without allowing the same developer to deploy any other services running in K8s?
    3. How do we prevent other services running in the cluster to talk to your service. Only Antaeus should be able to do it.

## How to run

If you want to run Antaeus locally, we've prepared a docker compose file that should help you do it. Just run:
```
docker-compose up
```
and the app should build and start running (after a few minutes when gradle does its job)

## How we'll test the solution

1. We will use your scripts to deploy both services to our Kubernetes cluster.
2. Run the pay endpoint on Antaeus to try and pay the invoices using your service.
3. Fetch all the invoices from Antaeus and confirm that roughly 50% (remember, your app should randomly fail on some of the invoices) of them will have status "PAID".

***

Hi there!

Many thanks for the technical challenge.

As instructed, I have created a payments service and added it to the Docker Compose environment, so it can run locally.

I have also provided the [deployment files](./kubernetes/) which have been tested on a local Kubernetes cluster.

Tests for the Payments Service can be run with the following command:

```
docker-compose run --rm -e RAILS_ENV=test payments rspec
```

The script `./run-challenge.sh` can be used to deploy both services to a local Kubernetes cluster. After deploying the services it will call the “make payment” endpoint until all invoices are paid, then clean up the environment.

#### Discussion points

Docker Compose is used to simulate the production environment. I isolated the development concerns into the `docker-compose.override.yml` file. This way, a full simulation of production can be achieved by running `docker-compose -f docker-compose.yml up`. The main differences are the volumes and Guard. The volumes allows for changes into the repo to be reflected in the runtime. Guard keeps RSpec (testing tool) running at all times, facilitante the TDD approach. As files changes, the related specs (tests) are ran.

##### Questions

###### How would a new deployment look like for these services? What kind of tools would you use?

Ideally the services would be deployed by a CD pipeline. Helm is a very known tool used for deployments and I prefer to use it for applications that are not deployed/updated frequently.

I have been using `kustomize` as it does not require any configuration in the cluster, which could compromise security (Tiller permissions). Helm 3 seems to have solved this problem though. `kustomize` is able to manage variants of a configuration, such as development, staging and production environments.

For critical services I would also consider using Terraform, especially if the underlying infrastructure was also provisioned using Infrastructure as Code. Terraform can be use to configure RBAC, logging and monitoring tools (Prometheus, Grafana, Filebeat, metrics-server, kube-metrics-server…), ingress controllers, etc. Terraform makes the implementation of a Disaster Recovery Plan easier. As it's cloud-agnostic, it could even be possible to move to different providers/accounts with virtually little or no changes in the code (only variables).

>   At this stage, the Payments app only have a small sample of tests for demonstration purposes. Preferably, a CI pipeline would also run some integration tests with the Antaeus service.

>   For simplicity, TLS certificates are not in use in this setup.

###### If a developers needs to push updates to just one of the services, how can we grant that permission without allowing the same developer to deploy any other services running in K8s?

There are a few ways of achieve that.

RBAC is one of them. Service Accounts, Users or Groups together with Cluster Roles, Roles and Namespaces could be a good start point. A developer would be granted access to a specific namespace or resource (based on resource types or name even). We could go as granular as we'd like: for example, a developer could have access to both namespaces (`antaeus` and `payments`), but only able to update/patch/destroy a deployment called `payments`.

I am aware of some other features such as ABAC and Pod Security Policy, but I don't have experience with them. They might be worth being spiked on.

If a CD pipeline is present, we could limit deployments to the CD tool (and of course, the Kubernetes admin). With Spinnaker, for example, even non technical employees would be able to deploy/rollback the service, and it's possible to schedule or add some rules like “no deployments on Friday or at night”. Authorisation would then happen inside the tool.

###### How do we prevent other services running in the cluster to talk to your service. Only Antaeus should be able to do it.

Network policies could be used to control ingress/egress between the 2 services.

On the app side, for redundancy, a token only known by Antaeus could be used to validate each request, but this is not the most secure option. JSON Web Tokens would work better.

