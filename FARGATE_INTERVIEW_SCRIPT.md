# Interview Script: EKS Fargate Deployment & Challenges 🎤

Agar interview (ya kisi presentation) mein aapse pucha jaye ki **"Aapne Finstack ko kaise deploy kiya aur kya problems face ki?"** toh aapko niche diya gaya structure aur answers use karne hain. Ye answers aapko ek **Senior DevOps/SRE Engineer** ki tarah present karenge.

---

## Question 1: "Can you explain your deployment process for Finstack?"
*(Aapne Finstack ko kaise deploy kiya?)*

**Aapka Jawab:**
"Humne Finstack ko AWS ECS se **EKS Fargate** par migrate kiya ek 100% serverless Kubernetes architecture achieve karne ke liye. 
Mera deployment process 3 phases mein divide tha:
1. **Infrastructure as Code (IaC):** Maine Terraform ka use karke VPC, Private/Public subnets, NAT Gateway aur EKS Cluster (v1.31) banaya. Saare worker nodes ko EC2 ke bajaye **Fargate Profiles** ke through provision kiya gaya taaki compute manage na karna pade.
2. **Kubernetes Configuration:** Applications ko private subnets mein deploy kiya. External traffic ko handle karne ke liye maine **AWS Load Balancer Controller** setup kiya jo automatically ek Application Load Balancer (ALB) provision karta hai jab hum Ingress resource apply karte hain. Security ke liye, maine **IRSA (IAM Roles for Service Accounts)** ka use kiya.
3. **Observability Stack:** Metrics aur monitoring ke liye Helm ka use karke **Prometheus aur Grafana** deploy kiya, jisme data persistence ke liye Amazon EFS attach kiya."

---

## Question 2: "What were the major challenges you faced during this EKS Fargate migration, and how did you solve them?"
*(Aapko kya problems aayi aur aapne unhe kaise solve kiya?)*

**Aapka Jawab (Explain these 3 real-world problems):**

### 🎯 Challenge 1: CoreDNS Pods Stuck in "Pending" State
- **Problem:** Jab EKS cluster up hua, toh default `CoreDNS` pods `Pending` state mein fass gaye the. Ye Fargate par schedule nahi ho rahe the, jiske wajah se cluster ke andar DNS resolution (jaise database ka connection) fail ho raha tha (`EAI_AGAIN` error).
- **How I Solved It:** Mujhe pata chala ki by default EKS mein CoreDNS ke deployment par ek annotation lagi hoti hai: `eks.amazonaws.com/compute-type: ec2`. Maine `kubectl patch` command ka use karke is annotation ko remove kiya. Jaise hi annotation hati, CoreDNS successfully Fargate profile par schedule ho gaya aur DNS issue resolve ho gaya.

### 🎯 Challenge 2: AWS Load Balancer Controller "AccessDenied"
- **Problem:** Maine ALB Ingress controller setup kar diya tha aur `Ingress` manifest bhi apply kar diya tha, lekin AWS par ALB create nahi ho raha tha. Logs check karne par `AccessDenied` exception dikhi, specially `wafv2:GetWebACLForResource` ke liye.
- **How I Solved It:** Ye issue IRSA (IAM Role for Service Account) ki permissions block hone ki vajah se tha. Purani policy incomplete thi. Maine AWS ki official, complete IAM policy (`iam_policy.json`) download ki jisme EC2, ELB, WAFv2, aur ACM ki saari zaroori permissions thi. Maine apne Terraform code (`irsa.tf`) ko update karke is official policy ko attach kiya. Iske baad ALB turant provision ho gaya.

### 🎯 Challenge 3: Persistent Storage on Fargate for Grafana (Database Locked)
- **Problem:** Fargate serverless hai, toh isme local EBS volume support nahi karta. Mujhe Prometheus aur Grafana ka data permanently save karna tha. Maine EFS setup kiya, par Grafana baar-baar crash ho raha tha with the error: `Database locked, sleeping then retrying`.
- **How I Solved It:** EFS ek distributed NFS (Network File System) hai. Grafana internally `SQLite` database use karta hai. Jab Kubernetes `RollingUpdate` deployment chala raha tha, toh naya pod boot ho jata tha jabki purana pod abhi bhi chal raha hota tha. Dono pods ek hi EFS file par lock lagane ki koshish kar rahe the, jo SQLite over NFS support nahi karta. Maine Helm chart mein Grafana ki deployment strategy ko `RollingUpdate` se change karke **`Recreate`** kar diya. Isse purana pod pehle completely kill hota hai aur lock release karta hai, aur phir check out hoke naya pod smoothly database connect kar leta hai.

---

## Final Tip for Interview:
Jab aap ye problems bata rahe hon, toh aapka tone **Confident Problem Solver** jaisa hona chahiye. Ye issues (CoreDNS Patching, IRSA debugging, aur EFS SQLite locking) basic level DevOps mein nahi aate hain, ye ek **Senior SRE** ka daily kaam dikhate hain!
