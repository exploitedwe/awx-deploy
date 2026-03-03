#RESOURCES
#https://github.com/ansible/awx-operator
#https://docs.ansible.com/projects/awx-operator/en/latest/installation/basic-install.html


#Update platform
sudo apt-get update && sudo apt-get upgrade -y
#Download k3 rancher kubernetes
curl -sfL https://get.k3s.io | sh -
#Fix user permissions for accessing kubernetes files
sudo chown michu:users /etc/rancher/k3s/k3s.yaml
#Check status to verify
kubectl get nodes

#Visit AWX documentation
#kustomize and operator
#kustomize
    # go to kubectl.docs.kubernetes.io/installation/kustomize/binaries/
    # The last good link i used is posted below, but monitor that https page above for updates
    curl -s "https://raw.githubusercontent.com/kubernetes-sigs/kustomize/master/hack/install_kustomize.sh" | bash
    # This gets that binary, but we need to move it
    sudo mv kustomize /usr/local/bin
    which kustomize #verify it is a command and where it is

# copy the kustomization.yaml file from the awx operator documentation into a new file
    # update the tag used to reference a real release

#########################
# RHEL ONLY NEEDS THIS SECTION
# 1. Open kubelet port and flannel VXLAN port in firewalld
sudo firewall-cmd --zone=public --permanent --add-port=10250/tcp
sudo firewall-cmd --zone=public --permanent --add-port=8472/udp

# 2. Enable masquerade for pod traffic NAT
sudo firewall-cmd --zone=public --permanent --add-masquerade

# 3. Trust CNI interfaces and pod CIDR so pod-to-host traffic isn't blocked
sudo firewall-cmd --zone=trusted --permanent --add-interface=cni0
sudo firewall-cmd --zone=trusted --permanent --add-interface=flannel.1
sudo firewall-cmd --zone=trusted --permanent --add-source=10.42.0.0/16

# 4. Apply all firewall changes
sudo firewall-cmd --reload

# 5. Deploy AWX via kustomize
kustomize build . | kubectl apply -f -

# 6. If AWX operator fails to reconcile, restart it to trigger a fresh attempt
kubectl rollout restart deployment/awx-operator-controller-manager -n awx

# Monitor progress
kubectl get pods -n awx -w




# 6. Open AWX web UI NodePort
sudo firewall-cmd --zone=public --permanent --add-port=30080/tcp
# OR WHATEVER NODEPORT_PORT YOU SET IN THE awx.yaml
sudo firewall-cmd --reload

########################

#kickoff the kustomize build against this kustomization.yml
kustomize build . | kubectl apply -f -
# if failed check that the tag aws made for kubectl
kubectl get pods --namespace awx

#make your awx.yaml file based on the documentation for it online
# add nodeport_port: 30080    #to get port 30080 as its port
# reference the awx.yaml file after the github reference in the kustomization.yaml file
# kickoff the kustomize build against this kustomization.yml

#rebuild and apply
kustomize build . | kubectl apply -f -

#watch logs and await start
kubectl logs -f deployments/awx-operator-controller-manager -c awx-manager --namespace awx
#await PLAY RECAP*********************** line

#look at pods, we're awaiting for all the awx pods to complete and be in a "Running" state
kubectl get pods -n awx

#get password and login
kubectl get secret awx-demo-admin-password -n awx -o jsonpath="{.data.password}" | base64 --decode ; echo

#Changing the default password
kubectl get pods -n awx
#make note of the "web" kubernetes pod
(kubectl exec -it -n awx [awx-web-xxxxxxxx] -- /bin/bash) #where [awx-web-xxxxxxxx] is the name of web pod
awx-manage changepassword admin #follow prompts to change password  
#OR
# kubectl exec -it awx-demo-web-57d5fdfbd4-cjk7b -c awx-demo-web -n awx -- awx-manage changepassword admin 
# where the awx-demo-web-57d5fdfbd4-cjk7b is the name of the web pod, and awx-demo-web is the name of the container in that pod
# The second one worked for me on RHEL, but the first one worked on ubuntu

