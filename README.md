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

As instructed, I have created a payment service and added it to the Docker Compose environment so it can be tested locally.

I have also provided the [deployment files](./kubernetes/) that should be deployed with Kustomize (see below).

>   **About Kustomize**
>
>   `kustomize` lets you customize raw, template-free YAML files for multiple purposes, leaving the original YAML untouched and usable as is.
>
>   `kustomize` targets kubernetes; it understands and can patch kubernetes style API objects. It's like [`make`], in that what it does is declared in a file, and it's like [`sed`], in that it emits edited text.
>
>   This tool is sponsored by [sig-cli] ([KEP]), and inspired by [DAM].

#### Running the demo

##### Requirements

-   Docker

-   Docker Compose

-   Kustomize

    Instructions on how to install Kustomize [here](https://github.com/kubernetes-sigs/kustomize/blob/master/docs/INSTALL.md).

    ```
    # TL;DR:
    curl -s "https://raw.githubusercontent.com/kubernetes-sigs/kustomize/master/hack/install_kustomize.sh" | bash
    ```

-   kubectl

-   A Kubernetes cluster with an Ingress Controller installed.

    This demo has been tested on the local Kubernetes from Docker Desktop for Mac. If you're also using Kubernetes from Docker Desktop for Mac and an ingress controller is not present, please run:

    ```
    make install-requirements-mac
    ```

    To uninstall:

    ```
    make remove-requirements-mac
    ```

-   [`jq`] will help to format some outputs and make them more readbale.

-   (Optional) To test it using the browser, please add `test.development.com` to your `/etc/hosts`. If using `curl`, this step is not necessary, as you can simply pass `-H 'Host: test.development.com'`.

##### How to run

With a Kubernetes cluster available, `kubectl` pointing to it, and the requirements installed (Ingress Controller, Kustomize…), run `make setup` to deploy the resources.

The script `run-challenge.sh` can deploy the services and also test the endpoints.

In a nutshell, this script simulates the steps you would run manually:

1.  It runs `make setup` to create the necessary resources in the cluster.

    >   You can run `kustomize build ./kubernetes/overlays/development` to check the YAML that will be applied.

2.  After waiting for the pods to be ready, it calls `curl -k -H 'Host: test.development.com' 'https://localhost/rest/health'` to verify the service is reacheable.

    >   If you've added `test.development.com` to your `/etc/hosts`, then `curl -k 'https://test.development.com/rest/health'` can be used.

3.  It calls `curl -k -H 'Host: test.development.com' -XPOST 'https://localhost/rest/v1/invoices/pay'` until all invoices are paid.

    `curl -k -H 'Host: test.development.com' 'https://localhost/rest/v1/invoices'` can be used to check out what invoices have been paid.

4.  It removes all resources created on step 1.

These two files are used to run the demo:

-   `Makefile`

    This contains some recipes that represent the development workflow.

    Helpers:

    -   `make install-requirements-mac` helps to setup Ingress Controller on Docker for Mac (if it's not present).

    -   `make remove-requirements-mac` reverts the changes made by the previous recipe.

    “CI simulation” [not required for the demo as the images have already been published]:

    -   `make build` builds all images used by this project.

    -   `make login` is not very useful if used on its own, it's a requirement for the push recipe.

    -   `make test` runs the tests to ensure images are only pushed if the tests pass. Tests for the Antaeus are currently missing.

    -   `make push` is the equivalent of calling `make push-antaeus` and `make push-payments`. It publishes the images to the private Docker repository.

        Should you wish to use it, please update the variables `DOCKER_IMAGE_PREFIX` and `DOCKER_REGISTRY_HOST` accordingly and create the repositories.

        For example, if you have repositories hosted on hub.docker.com:

        ```
        …
        ifeq ($(ENV), staging)
            …
            DOCKER_IMAGE_PREFIX  := <username>
            DOCKER_REGISTRY_HOST := <blank>
            …
        ```
        ```
        ENV=staging make push
        ```

        >   Note that to use `ENV=staging` you might need to edit some files. For example, the TLS certificate, domain for the ingress…

        >   Run `kustomize build ./kubernetes/overlays/staging` to check the final YAML without applying it.

    Kubernetes (“CD simulation“):

    -   `make setup` will create the necessary resources. It should call `push`, but as you won't have access to my private repository (hard coded on the Makefile) and to simplify this demo, I commented it out. Feel free to replace

        ```
        setup: # push
        ```

        with

        ```
        setup: push
        ```

        if you update the variables to build and publish images to your own private repository. See `make push` comment above.

    -   `make update` should be called every time a Kubernetes resource is updated. For example, to add/remove config maps, add environment variables to deployments, etc. Keep in mind that if you remove a resource, you must delete it manually with `kubectl`.

    -   `make cleanup` destroys all resources created with `make setup`.

    -   `make deploy` is the same as calling `make deploy-antaeus` and `make deploy-payments` but has very little value for this demo. It's here simply to demonstrate how code changes to the project can be deployed with Kustomize. To test it, you're required to use your own private repository because `make push` will be called.

        Apart from building and publishing the image with the code changes, this task updates the deployment files in the repo to reflect the tag change, ensuring the deployment files in this repository are the single source of truth of the cluster. [GitOps]

        ```
        images:
        - name: antaeus
          newName: rickbgs/tinjis-antaeus
          newTag: "20200227"
        - name: payments
          newName: rickbgs/tinjis-payments
          newTag: "20200227"

        ```

-   `run-challenge.sh`

    This script tests the whole worflow. Using the `Makefile`, it deploys both Antaeus and Payment services to a Kubernetes cluster, calls the “make payment” endpoint until all invoices are paid, and finally reverts all the changes to the environment. It can be called several timess in a row.

#### Discussion points

Docker Compose is used to simulate the production environment. I isolated the development concerns into the `docker-compose.override.yml` file. This way, a full simulation of production can be achieved by running `docker-compose -f docker-compose.yml up`. The main differences are the volumes and Guard. The volumes allows for changes into the repo to be reflected in the runtime. Guard keeps RSpec (testing tool for the Ruby on Rails project) running at all times, facilitante the TDD approach. As files changes, the related specs (tests) are ran.

##### Questions

###### How would a new deployment look like for these services? What kind of tools would you use?

Ideally the services would be deployed by a CD pipeline.

Helm is a very known tool used for deployments and at the company I currently work for I prefer to use it for applications that are not deployed/updated frequently, like third party projects. When working with several teams that were new to the world of containers, Docker and Kubernetes, Helm added a lot of confusion. It was not easy for a developer to understand what was going on in the charts due to the several conditionals in the templates. They couldn't easily tell what was the value of a variable at a certain time either. It was a complexity we didn't need in that moment. We have one cluster for each environment, and we also need some access isolation between teams. We would have to deal with multiple Tillers (for different accesses), which would also add another layer of complexity we couldn't afford when using CD tools. — 1-person SRE team for 6 teams of developers that were all new to containers/Kubernetes wasn't an ideal scenario, so simplicity was even more encouraged.

For those reasons we chose Kustomize. I made some notes about how Kustomize helped us below. It does not require any configuration/changes in the cluster, so it helps with cluster maintainance and access management. The templates, without conditions and placeholders, are less complex to newbies. Kustomize is able to manage variants of a configuration, such as development, staging and production environments and has become part of Kubernetes (since version 1.14). It's available in `kubectl` through the `-k` flag (e.g. for commands like apply, get) and the `kustomize` subcommand.

The `Makefile` will help to demonstrate Kustomize. I am using the native Kustomize here, not `kubectl kustomize`.

Feel free to change the variables in the Makefile to build/push images to your own Docker registry/repository if you want to use different ones than mine.

```
make push
```

```
kustomize build ./kubernetes/overlays/development # | kubectl create|apply|delete -f -
kustomize build ./kubernetes/overlays/staging     # | kubectl create|apply|delete -f -
kustomize build ./kubernetes/overlays/production  # | kubectl create|apply|delete -f - # files are not provided
```

Some notes:

-   GitOps

    Kustomize helps with GitOps by keeping the templates up to date. Regular changes such as image updates happen in one place and not in several deployment files.

-   Kustomize can modify the names of resources in a consistent manner.

    Because the base contains
    ```
    namePrefix: tinjis-
    ```
    all resources names will have this prefix.

    The development overlay specify that
    ```
    nameSuffix: -dev
    ```
    so all resources generated for that overlay will have that suffix in adition to the chosen prefix.


    The template:
    ```
    ---
    apiVersion: v1
    kind: Service
    metadata:
      name: api
      namespace: antaeus
    …
    ---
    # Ingress:
    spec:
      …
            backend:
              serviceName: api
              servicePort: 8080

    ```
    will output:
    ```
    spec:
      rules:
      - host: test.development.com
        http:
          paths:
          - backend:
              serviceName: tinjis-api-dev # The template just uses `api` as the name.
              servicePort: 8080
    ```
    as all references to api service are replaced with `tinjis-api-dev`.

-   You can provide all templates without the namespaces and apply them to all resources with `kustomize build` by using `namespace: <name>` in the base, instead of changing the kubectl context. In this setup I avoided doing so to keep it simple, as this repository makes use of two namespaces.

    This can be a powerful tool. For example, a company would be able to setup a different namespace for each developer in the development cluster as overlays can be extended.

-   Kustomize is able to add annotations and labels to all resources with ease.

    I encourage teams to use labels to facility tasks like Kubernetes upgrades and debugging. For example:

    ```
    kubectl get --all-namespaces pods -l app.kubernetes.io/managed-by=<Team Name> --field-selector=status.phase!=Running
    ```

    As the global labels can be managed in one place, it reduces the chances for a team to forget to label a new deployment or statefulset resource. The same is true when some of the labels need to be updated.

    ```
    # base/kustomization.yaml
    # This ensure all resources contains at least these labels.
    commonLabels:
      app.kubernetes.io/managed-by: Pleo
      app.kubernetes.io/part-of: tinjis
    ```

    ```
    # overlays/<overlay>/kustomization.yaml
    # This ensure all resources of the overlay contains this label.
    commonLabels:
      app.kubernetes.io/instance: development
    ```

-   You can pecify different replicas depending on the overlay in one place. For example, 1 replica for development and 3 for production. The same for image names and tags.

    ```
    # Instead of changing those values in the deployment resources…
    replicas:
    - count: 1
      name: antaeus-api
    - count: 1
      name: payments-api
    ```

-   By using patches you can add/remove/replace settings, like settings up resources for the deployments, affinities, tolerations, etc. Kustomize uses targets for that.

    An interesting thing with target is that it's future proof. For example, if you add a deployment with a certain name that matches the target, it will benefit from the patch even if you had forgotten about it.

    ```
    # If a deployment called antaeus-nginx is added, both  antaeus-nginx and antaeus-api will benefit from the patch.
    patches:
    - path: ./patches/antaeus-node-affinity.yaml
      target:
        kind: Deployment
        name: antaeus.*
    ```

    Of course you need to be careful because this can also work against you if you don't target well. Targets can use labels, annotations, resource kind, version, name…

    I added one using annotations for demonstration purposes.

    ```
    # To automatically add this toleration to a deployment, simply annotate it with toleration=sre-team.
    - path: ./patches/tolerations-sre-team.yaml
      target:
        kind: Deployment
        annotationSelector: "toleration=sre-team"
    ```

-   ConfigMaps and Secrets can be stored as Property Files and generated on-the-fly.

    Kustomize can also append a hash to the config map or secret name, so every time a change occurs a different name is given, which can facilitate rollback. This can be tricky though, as one might end up with several versions of a config map. References to the secret/config map are updated accordingly. For example, if a config map is generated with a hash, you can continue using `valueFrom.secretKeyRef.name: rails`, and Kustomize will replace `rails` with the new generated name (example: rails-x384s.

    To demonstrate the secrets generator, I am also provisioning a self-signed certificate.

    >   To test the Ingress, a Ingress Controller is meant to be pre-installed.
    >
    >   Docker for Mac:
    >
    >   ```
    >   kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/nginx-0.29.0/deploy/static/mandatory.yaml
    >   kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/nginx-0.29.0/deploy/static/provider/cloud-generic.yaml
    >   ```
    >
    >   For other providers (such as minikube), please refer to [this page](https://kubernetes.github.io/ingress-nginx/deploy/) if an Ingress Controller is not present.

    The certificate is for the domain _test.development.com_, so please add
    ```
    127.0.0.1       test.development.com # the IP might be different, for minikube try `minikube ip`
    ```
    to your `/etc/hosts`.

    In the command line, use `curl -k -H 'Host: test.development.com' 'https://<ip>/rest/v1/invoices'`.

For critical services I would also consider using Terraform, especially if the underlying infrastructure was also provisioned using Infrastructure as Code. Terraform can be use to configure RBAC, logging and monitoring tools (Prometheus, Grafana, Filebeat, metrics-server, kube-metrics-server…), ingress controllers, etc.

Terraform also makes the implementation of a Disaster Recovery Plan easier. As it's cloud-agnostic, it could even be possible to move to different providers/accounts with virtually little or no changes in the code (only variables).

>   At this stage, the Payments app only have a small sample of tests for demonstration purposes. Preferably, a CI pipeline would also run some integration tests with the Antaeus service.

###### If a developers needs to push updates to just one of the services, how can we grant that permission without allowing the same developer to deploy any other services running in K8s?

There are a few ways of achieve that.

RBAC is one of them. Service Accounts, Users or Groups together with Cluster Roles, Roles and Namespaces could be a good start point. A developer would be granted access to a specific namespace or resource (based on resource types or name even). We could go as granular as we'd like: for example, a developer could have access to both namespaces (`antaeus` and `payments`), but only able to update/patch/destroy a deployment called `payments`.

I am aware of some other features such as ABAC and Pod Security Policy, but I don't have experience with them. They might be worth being spiked on.

If a CD pipeline is present, we could limit deployments to the CD tool (and of course, the Kubernetes administrator). With Spinnaker, for example, even non technical employees would be able to deploy/rollback the service, and it's possible to schedule or add some rules like “no deployments on Friday or at night”. Authorisation would then happen inside the tool.

###### How do we prevent other services running in the cluster to talk to your service. Only Antaeus should be able to do it.

Network policies could be used to control ingress/egress between the 2 services.

On the app side, for redundancy, a token only known by Antaeus could be used to validate each request, but this is not the most secure option. JSON Web Tokens would work better.

[`jq`]: https://stedolan.github.io/jq/download/
[`make`]: https://www.gnu.org/software/make
[`sed`]: https://www.gnu.org/software/sed
[sig-cli]: https://github.com/kubernetes/community/blob/master/sig-cli/README.md
[DAM]: https://github.com/kubernetes-sigs/kustomize/blob/master/docs/glossary.md#declarative-application-management
[KEP]: https://github.com/kubernetes/enhancements/blob/master/keps/sig-cli/0008-kustomize.md
