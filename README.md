# 🚀 Referral System Contract

![Ethereum](https://img.shields.io/badge/Network-Holesky_Testnet-blue?style=flat-square&logo=ethereum)
![Foundry](https://img.shields.io/badge/Deployed_With-Foundry-orange?style=flat-square)
![Etherscan Verified](https://img.shields.io/badge/Contract_Verified-Yes-green?style=flat-square)

## 📜 Description

The **Referral System** smart contract implements a decentralized **Referral Program** for token distribution, allowing users to refer others and earn rewards. This contract operates on the **Ethereum blockchain** and integrates with the **ReferralToken** contract for reward distribution. The system is optimized for privacy and gas efficiency by storing user data in hashed format.

### **Key Features:**

- 👥 **User Registration**: Users can register and join the referral program, either independently or with a referrer.
- 🏅 **Referral Rewards**: Both referrers and referees earn rewards in the form of tokens upon successful registration.
- 🔗 **Referral Tracking**: The system tracks referrals and ensures there are no circular referrals.
- 💸 **Reward Distribution**: Tokens are minted and distributed to both the referrer and referee upon successful referral registration.
- 🔒 **Privacy**: User names and emails are hashed and stored for privacy while still enabling verification.
- ⚖️ **Roles**: Supports operator roles for administrative actions and includes access control for specific functions.
- 🔄 **Flexible Reward Amounts**: Admins can update the referral reward amounts at any time.

---

## 📡 Deployment Details
- **Network:** Ethereum (Holesky Testnet)
- **Chain ID:** `17000` <!-- Add Chain ID if applicable -->
- **ReferralToken Contract Address:** [`0x010309FB34930C11e274C63b84317c6Ce7C8326B`](https://holesky.etherscan.io/address/0x010309FB34930C11e274C63b84317c6Ce7C8326B#readContract) <!-- Add your deployed contract address -->
- **Referral System Contract Address:** [`0x811D236aA01a2dcADE63Ca02db4a584ba398D0C5`](https://holesky.etherscan.io/address/0x811d236aa01a2dcade63ca02db4a584ba398d0c5#readContract) <!-- Add your deployed contract address -->
- **Etherscan Verification:** ✅ Verified
- **Explorer Link:** [View on Etherscan](https://holesky.etherscan.io/address/0x811d236aa01a2dcade63ca02db4a584ba398d0c5#readContract) <!-- Add link to verified contract on Etherscan -->

---

## 🛠 Installation & Setup  
Follow these steps to interact with the contract using Foundry:

### **Clone the repository**
```sh
git clone https://github.com/your-repository/Referral-System-Contract.git
cd Referral-System-Contract
