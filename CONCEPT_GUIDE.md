# 📘 EKS Conceptual Guide (Beginner Friendly)

Ye guide aapko **Finstack** ke naye "Kubernetes Architecture" ko asaan bhasha mein samjhane ke liye hai. Agar aap DevOps ya AWS mein naye hain, toh ye aapke liye perfect hai!

---

## 🏗️ 1. Architecture: Ek "Digital Home" Jaisa
Hamara poora EKS setup ek digital ghar (Real Estate) ke jaisa hai.

### **AWS EKS (The Neighborhood)**
Pehle hum ECS use kar rahe the (jo sirf AWS ka apna neighborhood tha). Ab hum **Kubernetes (EKS)** par hain.
*   **Kubernetes (K8s)**: Ye poore world ka standard hai. Ek baar isse sikh liya, toh aap Google Cloud ya Azure par bhi same asaan tarike se code chala sakte hain.
*   **Fargate (Serverless)**: Iska matlab hai humein ghar ki maintenance (Server Manage) nahi karni padti. AWS hamare liye hamesha rooms ready rakhta hai.

---

## 🌐 2. Networking: "The Safe Boundary"
Hamare network mein do main areas hain:

*   **VPC (Your Private Plot)**: Ye aapka apna ek private building block hai AWS ke andar.
*   **Public Subnets (The Front Yard)**: Yaha **ALB (Load Balancer)** baithta hai jo bahar ki duniya se traffic leta hai.
*   **Private Subnets (Safe Rooms)**: Aapke saare microservices (Auth, Payment) yaha rehte hain. Inhe bahar se koi direct access nahi kar sakta.
*   **NAT Gateway (A One-Way Door)**: Aapke private services internet par baat kar sakte hain, lekin internet unke andar nahi aa sakta.

---

## 📦 3. Kubernetes: "The Workers"
Kubernetes ke 3 sabse important parts jo humne use kiye hain:

### **A. Namespace (The Folder System)**
Humne **`finstack`** naam ka ek namespace banaya hai. Ye aapke cluster ke andar ek alag boundary hai taaki doosre projects se koi takkar na ho.

### **B. Deployments (The 24x7 Workers)**
`*-deployment.yaml` files instruction manual hain. 
*   Agar humne `replicas: 2` likha hai, toh K8s hamesha do workers (Pods) chala kar rakhega. 
*   Agar ek Pod crash ho jata hai, toh K8s turant naya Pod khada kar deta hai.

### **C. Services (The Static Extension Numbers)**
Pod ke IP address hamesha badalte rehte hain. 
*   **Service**: Ye ek static phone number ya extension jaisa hai jo hamesha fix rehta hai (`finstack-auth-service`). Workers badalte rahein, lekin number wahi rehta hai.

---

## 🚪 4. Ingress: "The Smart Receptionist"
User jab website par ata hai, toh Ingress decide karta hai kaha bhejna hai:
*   Jab koi `/api` request bhejta hai, **Ingress** use "Receptionist" ki tarah Gateway Service ke paas bhej deta hai.
*   Ye poora kaam **AWS Load Balancer Controller** manage karta hai.

---

## 🔐 5. Security: "Least Privilege"
Security ke liye humne **IRSA (IAM Roles for Service Accounts)** use kiya hai.
*   Iska matlab hai hum kisi bhi service ko poori building ki chahbi (Full Permission) nahi dete. 
*   Payment Service ko sirf utni hi chabhi milegi jitni usse payment process karne ke liye chahiye.

---

## 🚀 Flow Kaise Chalta Hai?
1.  **User** website open karta hai (`http://your-alb-dns.com`).
2.  Request **Public Subnet** ke **ALB** par pahunchti hai.
3.  **Ingress Rules** check karte hain:
    *   `/api` → Gateway
    *   `/` → Frontend
4.  Traffic **Private Subnet** ke andar jaata hai jaha aapke workers (Pods) chal rahe hain.

---

### **Aapki File Structure:**
- **[`/k8s/deployments`](file:///home/gitops/Desktop/finstack/k8s/deployments/)**: Instructions - kaunsi image chalani hai aur kitne workers chahiye.
- **[`/k8s/services`](file:///home/gitops/Desktop/finstack/k8s/services/)**: Extension numbers - andaro-andar baat karne ke liye.
- **[`/k8s/ingress`](file:///home/gitops/Desktop/finstack/k8s/ingress/)**: Entrance Gate - bahari traffic ke rules.
