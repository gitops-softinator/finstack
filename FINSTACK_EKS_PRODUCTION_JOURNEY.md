# Finstack Project: ECS to EKS Fargate Migration Journey 🚀

Ye document humari poori Finstack migration journey ki summary hai. ECS se lekar EKS Fargate tak, humne kya-kya kiya, kyun kiya, aur raste mein aayi hui mushkilon ko kaise solve kiya, sab isme cover kiya gaya hai.

---

## 1. Shuruaat: Humne Migrate Kyun Kiya? (Why EKS Fargate?)

Pehle Finstack AWS ECS par chal raha tha. Humne **EKS (Elastic Kubernetes Service) Fargate** par migrate karne ka faisla liya taaki:
- **Serverless Compute:** Fargate ke saath hume EC2 nodes ko manage, patch, ya upgrade karne ki zaroorat nahi padti.
- **Microservices Architecture:** Kubernetes 8 microservices (auth, gateway, frontend, mongodb, user, payment, transaction, notification) ko behtar tareeke se manage, scale aur self-heal kar sakta hai.
- **Enterprise Standard:** Kubernetes cloud-native applications ke liye industry standard hai.

---

## 2. Humne Kya-Kya Kiya? (Architecture & Steps)

1. **Infrastructure as Code (Terraform):** 
   - Humne VPC banaya (`10.0.0.0/16`) jisme Public aur Private subnets the.
   - NAT Gateway public subnet mein rakha taaki private subnet ke pods internet access kar sake bina directly expose hue.
2. **EKS Cluster & Fargate Profiles:**
   - 1.31 version ka cluster banaya.
   - Fargate profiles banaye `finstack`, `kube-system`, aur `monitoring` namespaces ke liye.
3. **AWS Load Balancer Controller:**
   - K8s cluster ko AWS ke Application Load Balancer (ALB) se baat karne ke liye Ingress controller setup kiya.
   - IAM Roles for Service Accounts (IRSA) ka use karke strict security di.

---

## 3. Raste Ki Mushkilein Aur Unke Solutions (Problems Faced & Fixed)

Humne migration ke dauran aayi bahut si complex problems ko troubleshoot kiya:

### A. ImagePullBackOff Error 🛠️
- **Problem:** Pods deploy nahi ho pa rahe the kyunki tags `:1.1` outdated the.
- **Solution:** Humne saare K8s deployment manifests ko update karke `:latest` tag use kiya, jisse containers smoothly chalne lage.

### B. CoreDNS Not Finding Nodes (Fargate Compute Issue) 🛠️
- **Problem:** CoreDNS pods `Pending` state mein the aur schedule nahi ho rahe the (database DNS resolve nahi ho raha tha, `EAI_AGAIN` error).
- **Solution:** Kube-system ke CoreDNS deployment par `eks.amazonaws.com/compute-type: ec2` annotation lagi thi. Humne is annotation ko remove kiya, jisse CoreDNS successfully Fargate par chalne laga.

### C. Ingress / ALB Provisioning Failure (AccessDenied) 🛠️
- **Problem:** Ingress resource ALB assign nahi kar pa raha tha. AWS Load Balancer controller logs mein `wafv2:GetWebACLForResource` ki *AccessDenied* errors aa rahi thi.
- **Solution:** Humne Terraform (`irsa.tf`) mein Controller ke IAM role ko update kiya. Pura official ALB IAM policy document (`iam_policy.json`) lagaya, jisse ALB address successfuly populate ho gaya.

---

## 4. Observability Stack: Prometheus & Grafana on Fargate 📊

Fargate serverless hai, iska matlab isme local hard drive (EBS) support nahi karta. Monitoring data (Prometheus Tsdb) aur dashboards (Grafana SQLite) ko permanently save karne ke liye hume **Amazon EFS** (Elastic File System) ka use karna pada. 

**Architecture Flow:**
1. **EFS Setup:** Humne EFS create kiya aur EFS Access Points banaye Prometheus (`uid:65534`) aur Grafana (`uid:472`) ke liye.
2. **EFS CSI Driver Issue:** Standard Helm add-ons require `privileged` node DaemonSets, jo Fargate allow nahi karta.
   - **Solution:** Humne Fargate ke native EFS capabilities ka use kiya (EFS mount transparently Fargate hypervisor se hota hai).
3. **Network Failure Setup:** VPC mein DNS hostnames enable kiya aur EFS Security Group ko VPC CIDR se allow kiya.
4. **Grafana SQLite Database Locked:** Fargate par Fargate pods EFS use karte the, jisme Grafana ka `sqlite3` database multi-writers ko handle nahi kar pata (crash `Database locked`).
   - **Solution:** Helm upgrade karte time deployment strategy ko `RollingUpdate` se `Recreate` kiya. Isse naya pod purane wale ke properly close hone ke baad hi ata hai, filesystem lock resolve ho gaya.

---

## 5. Conclusion 🎯
Finstack ab ek **True Serverless, Highly Available, aur Observable Enterprise Application** ban chuka hai. Private subnets security dete hain, Fargate scaling aur zero maintenance deta hai, aur EFS-backed Prometheus/Grafana deep tracking. Ye architecture "Top-Tier" DevOps / SRE standards ke bilkul barabar hai!
