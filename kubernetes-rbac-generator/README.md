# KubeRBAC
## Kubernetes RBAC / Config Generator
## What this script will do ?

As we know, there are times when it's necessary to provide access to a user with specific rules.

For example, bind him to a namespace or even more rigidly to an object -  deployment.

With the help of this script, you can easily do this.

For this script to work, follow the steps shown below

### Prepare Environment:

- Quick install:
```bash
$ curl https://raw.githubusercontent.com/graypit/Kubernetes-Codes/master/kubernetes-rbac-generator/kube-rbac.sh > /usr/bin/kube-rbac 2>/dev/null
$ chmod +x /usr/bin/kube-rbac
```
- Install with cloning repo:
```bash
$ mkdir /var/lib/devops-codes/
$ cd /var/lib/devops-codes/
$ git clone https://github.com/graypit/Kubernetes-Codes.git
$ chmod +x ./Kubernetes-Codes/kubernetes-rbac-generator/kube-rbac.sh
```
### Create alias for it:
```bash
$ echo "alias kube-rbac="/var/lib/devops-codes/Kubernetes-Codes/kubernetes-rbac-generator/kube-rbac.sh"" >> ~/.bashrc && source ~/.bashrc
```
### P.S For detail information just execute:
```bash
$ kube-rbac --help
```