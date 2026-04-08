# Interview Script: ECS to EKS Migration & Challenges 🎤

Agar interview (ya kisi presentation) mein aapse pucha jaye ki **"Aapne Finstack ko kaise deploy kiya aur kya problems face ki?"** toh aapko niche diya gaya structure aur answers use karne hain. Ye answers aapko ek **Senior DevOps/SRE Engineer** ki tarah present karenge.

---

## Question 1: "Can you explain your deployment process for Finstack?"
*(Aapne Finstack ko kaise deploy kiya?)*

**Aapka Jawab:**
"Humne Finstack ko **AWS ECS (Fargate) se EKS (Managed Node Groups)** par migrate kiya ek production-grade, portable Kubernetes architecture achieve karne ke liye. ECS proprietary tha aur Kubernetes ecosystem ka fayda nahi utha sakte the.

Mera deployment process 3 phases mein divide tha:
1. **Infrastructure as Code (IaC):** Maine Terraform ka use karke VPC, Private/Public subnets, NAT Gateway aur EKS Cluster (v1.31) banaya. Compute ke liye **Managed Node Groups** use kiye (`t3.medium` instances, auto-scaling 1 se 4 nodes tak) jo AWS automatically manage karta hai — provisioning, patching, AMI upgrades sab automated.
2. **Kubernetes Configuration:** Applications ko private subnets mein deploy kiya. External traffic ke liye **AWS Load Balancer Controller** setup kiya jo ALB auto-provision karta hai. Security ke liye **IRSA (IAM Roles for Service Accounts)** use kiya.
3. **Observability Stack:** **Prometheus aur Grafana** deploy kiya Helm se, data persistence EFS par. **FluentBit** DaemonSet se har node ke logs CloudWatch mein ship hote hain."

---

## Question 2: "Why did you migrate from ECS to EKS?"
*(ECS se EKS kyun migrate kiya?)*

**Aapka Jawab:**
"ECS Fargate par Finstack chal raha tha, lekin 5 major reasons thi migration ke liye:

1. **Portability:** ECS sirf AWS ka proprietary service hai. Kubernetes ek open-source industry standard hai — agar future mein Google Cloud, Azure, ya on-prem par jaana ho toh koi migration nahi karna padega.
2. **Ecosystem:** Kubernetes ka ecosystem kahin zyada rich hai — Helm charts, ArgoCD (GitOps), Prometheus, FluentBit DaemonSets, External Secrets Operator — ye sab ECS mein available nahi the ya bahut limited the.
3. **DaemonSets & Full Control:** ECS Fargate mein DaemonSets support nahi — FluentBit logging, CSI drivers jaise standard tools nahi chal sakte. EKS Managed Node Groups mein full EC2 capabilities milti hain.
4. **GitOps:** ECS mein GitOps (ArgoCD) properly implement nahi hota. EKS mein ArgoCD cluster ke andar hi rehta hai aur automatically Git se sync karta hai.
5. **Industry Standard for Resume:** Kubernetes experience industry mein bahut valuable hai, ECS experience comparatively niche hai."

---

## Question 3: "What were the major challenges you faced, and how did you solve them?"
*(Kya problems aayi aur kaise solve ki?)*

**Aapka Jawab (4 real-world problems):**

### 🎯 Challenge 1: CoreDNS Configuration Issues
- **Problem:** Jab EKS cluster up hua, CoreDNS pods properly schedule nahi ho rahe the. DNS resolution fail — `EAI_AGAIN` error, services apas mein communicate nahi kar pa rahi thi.
- **How I Solved It:** Maine CoreDNS deployment ki configuration verify ki aur ensure kiya ki wo managed nodes par properly schedule ho. Iske baad DNS resolution normal ho gaya.

### 🎯 Challenge 2: AWS Load Balancer Controller "AccessDenied"
- **Problem:** Maine ALB Ingress controller setup kar diya tha aur `Ingress` manifest bhi apply kar diya tha, lekin AWS par ALB create nahi ho raha tha. Logs check karne par `AccessDenied` exception dikhi, specially `wafv2:GetWebACLForResource` ke liye.
- **How I Solved It:** Ye issue IRSA (IAM Role for Service Account) ki permissions block hone ki vajah se tha. Purani policy incomplete thi. Maine AWS ki official, complete IAM policy (`iam_policy.json`) download ki jisme EC2, ELB, WAFv2, aur ACM ki saari zaroori permissions thi. Maine apne Terraform code (`irsa.tf`) ko update karke is official policy ko attach kiya. Iske baad ALB turant provision ho gaya.

### 🎯 Challenge 3: EFS Mount Failure (DNS Resolution)
- **Problem:** Prometheus aur Grafana pods ko EFS mount nahi ho raha tha — `FailedMount: Failed to resolve fs-xxx.efs.eu-north... connection refused`.
- **How I Solved It:** 2 issues the: (1) VPC mein `EnableDnsHostnames` disabled tha — enable kiya. (2) EFS Security Group mein NFS traffic (port 2049) allow nahi tha VPC CIDR se — rule add kiya. Dono fixes ke baad EFS mount successfully ho gaya.

### 🎯 Challenge 4: Grafana SQLite "Database Locked"
- **Problem:** Grafana baar-baar crash ho raha tha — `CrashLoopBackOff` with error `Database locked, sleeping then retrying`.
- **How I Solved It:** EFS ek distributed NFS hai. Grafana internally `SQLite` database use karta hai. Jab Kubernetes `RollingUpdate` deployment chala raha tha, toh naya pod boot ho jata tha jabki purana pod abhi bhi chal raha hota tha. Dono pods ek hi EFS file par lock lagane ki koshish kar rahe the, jo SQLite over NFS support nahi karta. Maine Helm chart mein Grafana ki deployment strategy ko `RollingUpdate` se change karke **`Recreate`** kar diya. Isse purana pod pehle completely kill hota hai aur lock release karta hai, aur phir naya pod smoothly database connect kar leta hai.

---

## Question 4: "What did you learn from this migration?"
*(Is migration se kya seekha?)*

**Aapka Jawab:**
"Is ECS se EKS migration se mujhe 3 key lessons mile:
1. **Kubernetes ecosystem is unmatched:** ECS Fargate mein basic container orchestration thi, lekin Kubernetes ka ecosystem (Helm, ArgoCD, Prometheus, IRSA) enterprise-grade platform banata hai.
2. **Managed Node Groups = best of both worlds:** AWS nodes ko manage karta hai (security patches, lifecycle), lekin hume full Kubernetes + EC2 capabilities milti hain — DaemonSets, EBS, privileged containers.
3. **Infrastructure as Code makes migrations safe:** Kyunki humara saara setup Terraform mein tha, poori migration controlled code changes thi — review, plan, apply. Manually karna almost impossible hota."

---

## Final Tip for Interview:
Ye ECS → EKS migration story **ek Senior SRE ka hallmark** hai. Ye dikhata hai ki aap:
- Production mein technology evaluate kar sakte ho
- Proprietary → Open Source migration kar sakte ho
- Complex infrastructure changes safely execute kar sakte ho (IaC)
- Kubernetes ecosystem tools deeply samajhte ho

**Boards ya interviewers ko ye bahut impress karta hai!** 💪
