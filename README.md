# AWS EKS base setup

Focus of this code is being concise, readable, and being pretty intuitive usable.

### How it works

You want to provide a couple of web applications inside of AWS in a secured way and don't want people to care about all the low-level details like TLS-Termination, redirection, Loadbalancers, DNS management, Authentication, etc.?

You might try this approach here. Terraform creates a new VPC with a single EKS cluster. It will provision a single ALB that is intended to be the single entry point and will take care of all the technical details above. It will then hand the request to the internal nginx ingress controller, that will hand it to the proper application to answer the request.

As a user you only need to provide your service and a small ingress object, where you can choose your hostname and where you deployed your service.

Everything else will be handled by the magic. ;)

The code here will especially take care of TLS termination, DNS management, and http-to-https redirection.
If you want to include other features like cognito authentication/SSO you can add this to the ALB config and it will be available for all you applications.

### How to run

````
vi terraform.tfvars                        # specify your base domain and cert
terraform init                             # initialize all providers
terraform apply                            # create the cluster
aws eks update-kubeconfig --name example   # connect to the new cluster
kubectl apply -f debug.yaml                # (optional) deploy a sample service (you probably want to replace domain and cert here, too.)
````

### Caveat

We assume the public address of the ALB will never change. If that happens nginx will still provide the original address and thinks will break.
A [--publish-ingress option](https://github.com/kubernetes/ingress-nginx/issues/5231) in nginx would take care of this, but is currently not present.

Of course feel free to change and improve the code. Feedback is always much appreciated!
